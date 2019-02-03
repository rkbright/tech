/** OTR Compensation / Pension: GWOT Period of Service**/

drop table ABR_GWOT;
create table ABR_GWOT as
select /*+ PARALLEL(default) */ a.claim_number as file_nbr, p.ptcpnt_id
    from adhoc_gwot.gwot_comb_roster a,
         common_ss.ss_person p
    where a.job_out_sid = 100 
        and nvl(a.claim_number, a.ssn) = p.file_nbr(+);

drop table ABR_OTR_a;
create table ABR_OTR_a as
 select distinct /*+ PARALLEL(default) */
        b.file_nbr,
        b.ptcpnt_vet_id||b.ptcpnt_bene_id as VET_BENE_ID, 
        b.ptcpnt_vet_id, 
        b.ptcpnt_bene_id,
        b.benefit_level_1_desc as BENE_TYPE,
        b.gross_amount,
        b.cdd,
        b.postal_code,
        b.residence_code,
        a.zip_code,
        b.gender_cd,
        b.age as age_corp_base,
        a.age,
        b.authzn_date,
        a.my_cnt,
        b.alr_mlty_svc_per_cd,
        b.military_svc_period_desc
    from z_abr.abr_running_13_master_final a,
         z_abr.abr_fy13_corp_base b
    where a.ptcpnt_vet_id(+) = b.ptcpnt_vet_id
        and a.ptcpnt_bene_id(+) = b.ptcpnt_bene_id
        and a.benefit_level_1_desc(+) = b.benefit_level_1_desc
        ;

drop table ABR_OTR_2013;
create table ABR_OTR_2013 as 
 select a.*,
        case when g.ptcpnt_id is not NULL and a.military_svc_period_desc = 'Gulf War' then 'GWOT' else a.military_svc_period_desc end POS_NEW,
        case when g.ptcpnt_id is not NULL and a.military_svc_period_desc = 'Gulf War' then 1 end GWOT
    from ABR_OTR_a a,
         ABR_GWOT g
    where a.ptcpnt_vet_id = g.ptcpnt_id(+);

select * from ABR_OTR_2013 ;

----------------------------
/** VALIDATION CODE, POS RESULTS **/
--COMPENSATION PERIOD OF SERVICE
-->Move 'Philippine Pesos' to WWII, to match 2012 format 
SELECT POS_NEW,
       vet_cnt, vet_distinct,
       ROUND(ben_amt,0) ben_amt,
       ROUND(ben_amt/vet_cnt,0) avg_amt
FROM  (SELECT POS_NEW,
              COUNT(*) vet_cnt, COUNT(distinct ptcpnt_vet_id) vet_distinct,
              SUM((GROSS_AMOUNT * 12))  ben_amt
       FROM  ABR_OTR_2013 a
       WHERE  BENE_TYPE = 'Compensation' 
       and my_Cnt =1
       GROUP BY POS_NEW
       UNION ALL
       SELECT 'Total' POS_NEW,
              COUNT(*) vet_cnt, COUNT(distinct ptcpnt_vet_id) vet_distinct,
              SUM((GROSS_AMOUNT * 12))  ben_amt
       FROM   ABR_OTR_2013 a
       WHERE  BENE_TYPE = 'Compensation' 
        and my_Cnt =1
        )
ORDER BY (CASE WHEN POS_NEW = 'World War I' THEN 1
               WHEN POS_NEW = 'World War II' THEN 2
               WHEN POS_NEW = 'Korean Conflict' THEN 3
               WHEN POS_NEW = 'Vietnam Era' THEN 4
               WHEN POS_NEW = 'Gulf War' THEN 5
               WHEN POS_NEW = 'Gulf War' THEN 6
               WHEN POS_NEW = 'Peacetime Era' THEN 7
               WHEN POS_NEW = 'Philippine Pesos' THEN 8
               WHEN POS_NEW = 'Unknown' THEN 9
               WHEN POS_NEW = 'Total' THEN 10
               ELSE 11
          END);
-------------------------------------------------------
--Pension and Compensation OTR
--5-1-c (bundle 1)
SELECT  -- source_award, 		
a.BENE_TYPE, COUNT (*) vet_cnt,	count(distinct file_nbr) as vet_cnt_distinct, count(distinct ptcpnt_vet_id) as dist_vet_id,	
         SUM (GROSS_AMOUNT) * 12 ben_amt ,		
           ROUND((SUM (GROSS_AMOUNT) * 12) /COUNT (*),0) avg_amt		
    FROM ABR_OTR_2013 a --WHERE my_Cnt =1		
GROUP BY  --source_award, 		
a.BENE_TYPE		
order by  (CASE WHEN a.BENE_TYPE  = 'Compensation' THEN 1		
                WHEN a.BENE_TYPE =  'DIC'   THEN 2   		
                WHEN a.BENE_TYPE = 'Veteran Pension' THEN 3  		
                WHEN a.BENE_TYPE = 'Survivor Pension'    THEN 4  
           END); 
--------
--5-2 Survivor Pension OTR
select BENE_TYPE, /*count(distinct a.ptcpnt_bene_id), count(distinct a.ptcpnt_vet_id) VET_CNT, sum(a.gross_amount), */
    count(*) BENE_CNT, sum(a.gross_amount*12), sum(a.gross_amount*12)/count(*) 
from (
    select b.*, ROW_NUMBER() OVER(PARTITION BY b.ptcpnt_bene_id ORDER BY b.authzn_date DESC) AS row_rank
    from ABR_OTR_2013 b
    where BENE_TYPE in ('Survivor Pension')
    ) a
where row_rank=1
group by BENE_TYPE;   
--------------------------------------------------------------------------------
/** OTR Pension **/
--26-3.02: Veterans Receiving Pension by Age (old: 22-3)		
create table OTR_Pension_union as				
SELECT  *
       FROM (
        select b.*, 
               CASE WHEN b.entitlement_desc in ('Pension') and SUBSTR (b.entlmt_type_cd, -1) IN ('L')  THEN 'PL 95-588 New Law Pension'
                    WHEN b.entitlement_desc in ('Pension') and SUBSTR (b.entlmt_type_cd, -1) IN ('2')  THEN 'Protected (Old Law) Pension'
                    WHEN b.entitlement_desc in ('Pension') and SUBSTR (b.entlmt_type_cd, -1) IN ('4')  THEN 'Section 306 Pension'
                    WHEN b.entitlement_desc in ('Pension') and SUBSTR (b.entlmt_type_cd, -1) IN ('3')  THEN 'Other Pension Programs'
                END veteran_pension_typ,
              ROW_NUMBER() OVER(PARTITION BY b.ptcpnt_vet_id ORDER BY b.authzn_date DESC) AS row_rank
        from abr_fy13_corp_base  b 
        where b.benefit_level_1_desc = 'Veteran Pension' 
        ) a
  where row_rank=1
UNION ALL
--37-3.03: Surviving Spouses Receiving Survivors Pension at End of Fiscal Year
SELECT *
FROM (  
 select b.*, 
        CASE  WHEN b.entitlement_desc in ('Death Pension') and SUBSTR (b.entlmt_type_cd, -1) IN ('D')  THEN 'PL 95-588 New Law Pension'
              WHEN b.entitlement_desc in ('Death Pension') and SUBSTR (b.entlmt_type_cd, -1) IN ('6')  THEN 'Protected (Old Law) Pension'
              WHEN b.entitlement_desc in ('Death Pension') and SUBSTR (b.entlmt_type_cd, -1) IN ('8')  THEN 'Section 306 Pension'
            END    survivor_pension_typ,
        ROW_NUMBER() OVER(PARTITION BY b.ptcpnt_bene_id ORDER BY b.authzn_date DESC) AS row_rank
    from abr_fy13_corp_base b
    where b.benefit_level_1_desc in ('Survivor Pension')
        --and SUBSTR (b.entlmt_type_cd, -1) IN ('D') -- 'PL 95-588 New Law Pension'
        --and SUBSTR (b.entlmt_type_cd, -1) IN ('6', '8' ) --Other Programs (0)
       --and AWARD_EVENT_AWARD_TYPE_CODE IN ('CPDS')
    ) a
where row_rank=1 ;
                
select count(*) from OTR_Pension_union; --518,566
select * from OTR_Pension_union; --518,566
select distinct a.military_svc_period_desc, count(*) from OTR_Pension_union a where benefit_level_1_desc = 'Veteran Pension' 
 group by military_svc_period_desc ;

--------------------------
--Veteran AA/HB
SELECT  *
        FROM     ABR_FY13_LPEN2 AA, edw_cp.RESIDENCE_DIM R
        WHERE    DISBILITY_TYPE IN ('HB','AA') AND AA.STATE_LIST = R.RESIDENCE_CODE(+);


--Survivor AA/HB
SELECT  *
        FROM     ABR_DPEN_INT  AA, edw_cp.RESIDENCE_DIM R
        WHERE    DISBILITY_TYPE IN ('HB','AA') AND AA.STATE_LIST = R.RESIDENCE_CODE(+);

