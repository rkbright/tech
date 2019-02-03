


--create table and import flat file "excel" in the ad hoc folder
create table Withdrawn (
LIN                  varchar(30)     not null,
CPTS                 varchar(10)     not null,
STATUS_DT            date            not null,
PM_ASSIGNMENT_DT     date            not null,
DII                  varchar(50)     not null);

select count(*) from Withdrawn;
grant select on Withdrawn to public;


--join test
select count(*) from cpts_ss.SS_TBLPROPERTY a join WITHDRAWN b on a.PLOANNUM =B.LIN  ;


--  Query
select distinct W.LIN,    
                D.SVCR_ID,
                D.SVCR_NM,
                D.ADDRS_ONE_TXT,
                D.ADDRS_TWO_TXT,
                D.CITY_NM,
                D.STATE_CD,
                D.ZIP_PREFIX_NBR,
                D.ZIP_FIRST_SUFFIX_NBR,
                A.PHLDRID loan_number,
                A.PFRMROWNR former_owner, 
                A.COHORT_YR cohort_yr, 
                A.FUND,
                a.PCASESTATUS property_status,
                sum(NVL(E.SPF_ACCRUAL_AMT,0)) SPF_accrual_amt,
                f.GROUP_CODE Reim_group_code,
                sum(NVL(f.reim_amt,0)) reim_amt,
                sum(NVL(SCRUB_FEE_AMT,0)) scrub_fee_paid,
                sum(NVL(AMT_PAID,0)) real_estate_tax_paid
from VBACOBRIGHK.WITHDRAWN w  left outer join CPTS_SS.SS_TBLPROPERTY a on a.PLOANNUM =w.LIN
                              join CPTS_SS.SS_PRPRTY_SCRUB_FEE b on a.id=b.pid
                              join CPTS_SS.SS_PRPRTY_TAX_PAID c on a.id=c.pid
                              join (select  distinct    SVCR_ID,
                                                        SVCR_NM,
                                                        ADDRS_ONE_TXT,
                                                        ADDRS_TWO_TXT,
                                                        CITY_NM,
                                                        STATE_CD,
                                                        ZIP_PREFIX_NBR,
                                                        ZIP_FIRST_SUFFIX_NBR,
                                                        STATUS_CD,
                                                        APRSL_CD,
                                                        SVCR_PIN
                                            FROM
                                                (SELECT distinct   svcr_id,
                                                                    svcr_nm,
                                                                    addrs_one_txt,
                                                                    addrs_two_txt,
                                                                    city_nm,
                                                                    state_cd,
                                                                    zip_prefix_nbr,
                                                                    zip_suffix_nbr zip_first_suffix_nbr,
                                                                    svcr_status_cd status_cd,
                                                                    aprsl_cd,
                                                                    svcr_pin
                                                        FROM eli_ss.ss_servicer)) d on a.phldrid=D.SVCR_ID
                                                        
                              join CPTS_SS.SS_PRPRTY_ACCRUAL e on a.id=e.pid
                              join (select  distinct y.id, x.mtge_loan_id, z.vin, z.group_code, sum(Z.RPTD_AMT) reim_amt                                                    
                                    from CPTS_SS.SS_OCWEN_ILM_TRNS z join CPTS_SS.SS_INVCE x on z.vin=x.VENDOR_INVCE_NUMBER
                                                                     join CPTS_SS.SS_TBLPROPERTY y on X.MTGE_LOAN_ID=y.id
                                    where Z.GROUP_CODE in('10','20','30','60')
                                    group by z.vin, z.group_code,y.id, x.mtge_loan_id
                                    ) f on a.id=f.id                                    
group by        W.LIN,   
                D.SVCR_ID,
                D.SVCR_NM,
                D.ADDRS_ONE_TXT,
                D.ADDRS_TWO_TXT,
                D.CITY_NM,
                D.STATE_CD,
                D.ZIP_PREFIX_NBR,
                D.ZIP_FIRST_SUFFIX_NBR,
                A.PHLDRID,
                A.PFRMROWNR, 
                A.COHORT_YR, 
                A.FUND,
                a.PCASESTATUS,
                f.GROUP_CODE      
;


