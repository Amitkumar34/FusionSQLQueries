SELECT *
    FROM (SELECT vendor_number,
                 TO_NUMBER (NVL (c_amt_due_remaining, 0)) tot_outst_sar,
                 due_date,
                 org_id,
                 due_dates,
                 org_name,
                 voucher_number,
                 vendor_name,
                 short_vendor_name,
                 vendor_id,
                 invoice_type_lookup_code,
                 vendor_type_lookup_code,
                 vendor_site_code,
                 reference_number,
                 address_id,
                 invoice_type,
                 invoice_id,
gl_date,
                 invoice_currency_code,
                 terms_name,
                 accts_pay_code_combination_id,
                 invoice_number,
                 po_num,
                 project_num,
                 installment_number,
                 DECODE (invoice_type,
                         'PREPAYMENT', (-1) * invoice_amount,
                         invoice_amount)
                    invoice_amount,
                 DECODE (invoice_type,
                         'PREPAYMENT', (-1) * gross_amount,
                         invoice_amount)
                    gross_amount,
                 invoice_date,
                 liability_acc,
                 days_past_due,
                 data_converted,
                 exchange_rate,
                 DECODE (invoice_type,
                         'PREPAYMENT', (-1) * amt_due_original,
                         amt_due_original)
                    amt_due_original,
                 c_amt_due_remaining,
                 day_over_due,
                 CASE
                    WHEN day_over_due <= 0 THEN c_amt_due_remaining
                    ELSE 0
                 END
                    not_due,
                 CASE
                    WHEN day_over_due BETWEEN 1 AND 30 THEN c_amt_due_remaining
                    ELSE 0
                 END
                    buk1_30,
                 CASE
                    WHEN day_over_due BETWEEN 31 AND 60
                    THEN
                       c_amt_due_remaining
                    ELSE
                       0
                 END
                    buk31_60,
                 CASE
                    WHEN day_over_due BETWEEN 61 AND 90
                    THEN
                       c_amt_due_remaining
                    ELSE
                       0
                 END
                    buk61_90,
                 CASE
                    WHEN day_over_due BETWEEN 91 AND 180
                    THEN
                       c_amt_due_remaining
                    ELSE
                       0
                 END
                    buk91_180,
                 CASE
                    WHEN day_over_due BETWEEN 181 AND 360
                    THEN
                       c_amt_due_remaining
                    ELSE
                       0
                 END
                    buk181_360,
                 CASE
                    WHEN day_over_due >= 361 THEN c_amt_due_remaining
                    ELSE 0
                 END
                    buk361
            FROM (SELECT aia.org_id,
                         hou.name org_name,
                         aia.doc_sequence_value voucher_number,
                         NVL (psv.vendor_name, hp.party_name) vendor_name,
                         NVL (psv.segment1, party_number) vendor_number,
                         NVL (psv.vendor_name, hp.party_name) short_vendor_name,
                         psv.vendor_id vendor_id,
                         aia.invoice_type_lookup_code,
                         psv.vendor_type_lookup_code,
                         NVL (pssv.vendor_site_code, sites.party_site_name)
                            vendor_site_code,
                         apsa.payment_num reference_number,
                         aia.vendor_site_id address_id,
                         aia.invoice_type_lookup_code invoice_type,
                         aia.invoice_id,
aia.gl_date,
                         apsa.due_date due_date,
                         TO_CHAR (apsa.due_date, 'DD-MON-RRRR') due_dates,
                         (TO_NUMBER (
                             TRUNC (apsa.due_date) - TRUNC (:p_to_date))
                          * -1)
                            day_over_due,
                         aia.invoice_currency_code,
                         (SELECT trm.name
                            FROM ap_terms_tl trm
                           WHERE trm.term_id = aia.terms_id
                                 AND trm.language = 'US')
                            terms_name,
                         aia.accts_pay_code_combination_id
                            accts_pay_code_combination_id,
                         aia.invoice_num invoice_number,
                         aia.invoice_amount,
                         apsa.gross_amount,
                         TO_CHAR (aia.invoice_date, 'DD-MON-RRRR') invoice_date,
                         (SELECT segment8
                            FROM gl_code_combinations
                           WHERE code_combination_id =
                                    aia.accts_pay_code_combination_id)
                            liability_acc,
                         CEIL (SYSDATE - apsa.due_date) days_past_due,
                         DECODE (aia.invoice_currency_code,
                                 apss.base_currency_code, ' ',
                                 DECODE (aia.exchange_rate, NULL, '*', ' '))
                            data_converted,
                         NVL (aia.exchange_rate, 1) exchange_rate,
                         DECODE (
                            aia.invoice_currency_code,
                            apss.base_currency_code, DECODE (
                                                        NVL (
                                                           apss.
                                                            minimum_accountable_unit,
                                                           0),
                                                        0, ROUND (
                                                              ( (NVL (
                                                                    apsa.
                                                                     gross_amount,
                                                                    0)
                                                                 / (NVL (
                                                                       aia.
                                                                        payment_cross_rate,
                                                                       1)))
                                                               * NVL (
                                                                    aia.
                                                                     exchange_rate,
                                                                    1)),
                                                              apss.precision),
                                                        ROUND (
                                                           ( (NVL (
                                                                 apsa.
                                                                  gross_amount,
                                                                 0)
                                                              / (NVL (
                                                                    aia.
                                                                     payment_cross_rate,
                                                                    1)))
                                                            * NVL (
                                                                 aia.
                                                                  exchange_rate,
                                                                 1))
                                                           / NVL (
                                                                apss.
                                                                 minimum_accountable_unit,
                                                                0))
                                                        * NVL (
                                                             apss.
                                                              minimum_accountable_unit,
                                                             0)),
                            DECODE (
                               aia.exchange_rate,
                               NULL, 0,
                               DECODE (
                                  NVL (apss.minimum_accountable_unit, 0),
                                  0, ROUND (
                                        ( (NVL (apsa.gross_amount, 0)
                                           / (NVL (aia.payment_cross_rate, 1)))
                                         * NVL (aia.exchange_rate, 1)),
                                        apss.precision),
                                  ROUND (
                                     ( (NVL (apsa.gross_amount, 0)
                                        / (NVL (aia.payment_cross_rate, 1)))
                                      * NVL (aia.exchange_rate, 1))
                                     / NVL (apss.minimum_accountable_unit, 0))
                                  * NVL (apss.minimum_accountable_unit, 0))))
                            amt_due_original,
                        -- (apsa.amount_remaining * NVL (exchange_rate, 1))   c_amt_due_remaining,
                         -----------------------------
          --( (NVL (apsa.gross_amount, 0))
          ( (NVL((SELECT SUM(AILA.AMOUNT) FROM AP_INVOICE_LINES_ALL AILA 
where AILA.INVOICE_ID=AIA.INVOICE_ID
and AILA.LINE_TYPE_LOOKUP_CODE <>'TAX'
and TO_DATE(AILA.ACCOUNTING_DATE,'yyyy-mm-dd') <=TO_DATE (TO_CHAR (:p_to_date, 'MM-dd-yyyy'),'MM-dd-yyyy')),0))
         + ( (NVL((SELECT SUM(AILA.AMOUNT) FROM AP_INVOICE_LINES_ALL AILA 
where AILA.INVOICE_ID=AIA.INVOICE_ID
and AILA.LINE_TYPE_LOOKUP_CODE ='TAX'
and AILA.PREPAY_INVOICE_ID is null),0)))
                  + ( (NVL((SELECT SUM(AILA.AMOUNT) FROM AP_INVOICE_LINES_ALL AILA, ZX_LINES ZL, AP_INVOICE_LINES_ALL AILA1 
where AILA.INVOICE_ID=AIA.INVOICE_ID
and AILA.LINE_TYPE_LOOKUP_CODE ='TAX'
and AILA.PREPAY_INVOICE_ID is not null
and AILA.SUMMARY_TAX_LINE_ID=ZL.SUMMARY_TAX_LINE_ID
and ZL.TRX_ID=AILA1.INVOICE_ID
and ZL.TRX_LINE_ID=AILA1.LINE_NUMBER
and TO_DATE(AILA1.ACCOUNTING_DATE,'yyyy-mm-dd') <=TO_DATE (TO_CHAR (:p_to_date, 'MM-dd-yyyy'),'MM-dd-yyyy')),0)))
        - NVL (
                       (SELECT SUM (amount)
                          FROM ap_invoice_payments p
                         WHERE     p.invoice_id = aia.invoice_id
                               AND p.payment_num = apsa.payment_num
                               AND p.accounting_date <= TO_DATE (TO_CHAR (:p_to_date, 'MM-dd-yyyy'),'MM-dd-yyyy')  ),
                       0)
             /* - DECODE (
                       aia.invoice_type_lookup_code,
                       'MIXED', 0,
                       (SELECT NVL (ABS (SUM (amount)), 0)
                          FROM ap_invoice_lines p
                         WHERE p.invoice_id = aia.invoice_id
                               AND line_type_lookup_code in ( 'PREPAY', 'TAX')
                               AND PREPAY_INVOICE_ID is not null
                               AND p.accounting_date <=
                                      TO_DATE (TO_CHAR (:p_to_date, 'MM-dd-yyyy'),'MM-dd-yyyy') )) */
                  - DECODE (
                       aia.invoice_type_lookup_code,
                       'PREPAYMENT', (SELECT ai.invoice_amount
                                        FROM ap_invoices ai
                                       WHERE ai.invoice_id = aia.invoice_id)
                                     - (SELECT NVL (SUM (ail.amount * (-1)), 0)
                                          FROM ap_invoice_lines ail
                                         WHERE ail.prepay_invoice_id =
                                                  aia.invoice_id
                                               AND ail.accounting_date <=
                                                      TO_DATE (TO_CHAR (:p_to_date, 'MM-dd-yyyy'),'MM-dd-yyyy') ),
                       0))
                    c_amt_due_remaining,
                         -------------------------------
                         ap_invoices_pkg.get_po_number_list (aia.invoice_id)   po_num,
                         (SELECT listagg (ppab.segment1, ',')
                                    WITHIN GROUP (ORDER BY ppab.segment1)
                            FROM pjf_projects_all_b ppab, ap_invoice_lines aid
                           WHERE     aia.invoice_id = aid.invoice_id
                                 AND aia.org_id = aid.org_id
                                 AND aid.pjc_project_id = ppab.project_id(+))
                            project_num,
                         apsa.payment_num installment_number
                    FROM ap_invoices aia,
                         ap_payment_schedules apsa,
                         hz_parties hp,
                         hz_party_sites sites,
                         poz_suppliers_v psv,
                         poz_supplier_sites_v pssv,
                         hr_operating_units hou,
                         (SELECT p.base_currency_code,
                                 c.precision,
                                 NVL (c.minimum_accountable_unit, 0)
                                    minimum_accountable_unit,
                                 c.description,
                                 p.org_id
                            FROM ap_system_parameters p, fnd_currencies_vl c
                           WHERE p.base_currency_code = c.currency_code) apss
                   WHERE     apsa.invoice_id = aia.invoice_id
--and aia.invoice_num='56446.'
                         AND apsa.org_id = aia.org_id
                         AND hp.party_id = aia.party_id
                         AND ap_invoices_pkg.get_posting_status (aia.invoice_id) = 'Y'
                         AND psv.vendor_id(+) = aia.vendor_id
                         AND pssv.vendor_site_id(+) = aia.vendor_site_id
                         AND pssv.vendor_id(+) = aia.vendor_id
                         AND apss.org_id = aia.org_id
                         AND hou.organization_id = aia.org_id
and hou.DEFAULT_LEGAL_CONTEXT_ID in (300003648416161,
300003694402320)
                         AND sites.party_id = hp.party_id
                         AND aia.invoice_type_lookup_code <> 'PREPAYMENT'
                         AND aia.party_site_id = sites.party_site_id
                         AND (aia.approval_status = 'APPROVED'
                              OR aia.wfapproval_status IN
                                    ('MANUALLY APPROVED', 'NOT REQUIRED'))
                         AND ( (aia.cancelled_date IS NOT NULL
                                AND TRUNC (aia.cancelled_date) > TO_DATE (TO_CHAR (:p_to_date, 'MM-dd-yyyy'),'MM-dd-yyyy')   )
                              OR (aia.cancelled_date IS NULL))
                         AND TRUNC (
                                (SELECT MIN (NVL (accounting_date, gl_date))
                                   FROM ap_invoice_distributions
                                  WHERE invoice_id = aia.invoice_id)) <= TO_DATE (TO_CHAR (:p_to_date, 'MM-dd-yyyy'),'MM-dd-yyyy') 
                         AND UPPER (hou.name) =
                                UPPER (NVL (:p_org_name, hou.name))
                         AND COALESCE (psv.vendor_type_lookup_code, 'null') =
                                NVL (
                                   :p_supplier_type,
                                   COALESCE (psv.vendor_type_lookup_code,
                                             'null'))
                         AND aia.party_id =
                                NVL (
                                   (SELECT party_id
                                      FROM hz_parties
                                     WHERE UPPER (party_name) =
                                              UPPER (:p_from_vendor_name)
                                           AND creation_date =
                                                  (SELECT MAX (creation_date)
                                                     FROM hz_parties
                                                    WHERE UPPER (party_name) =
                                                             UPPER (
                                                                :p_from_vendor_name)
                                                          AND created_by_module IN
                                                                 ('POS_SUPPLIER_MGMT',
                                                                  'TCA_FORM_WRAPPER'))),
                                   aia.party_id)
--                         AND aia.invoice_date <=   NVL (TO_DATE (TO_CHAR (:p_to_date, 'MM-dd-yyyy'),'MM-dd-yyyy') , aia.invoice_date)
) z
           WHERE c_amt_due_remaining != 0)
ORDER BY                                                       --tot_outst_sar
        DECODE (:p_sort_invoices_by, 1, vendor_number),
         DECODE (:p_sort_invoices_by, 2, tot_outst_sar),
         DECODE (:p_sort_invoices_by,
                 3, TO_CHAR (due_date, 'yyyymmddhh24miss'))
