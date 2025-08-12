CLASS zedoc_adaptor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_badi_interface .
    INTERFACES if_edoc_adaptor .
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS convert_currency_invoice     CHANGING ch_invoice TYPE edo_co21_send_invoice_request.
    METHODS convert_currency_credit_note CHANGING ch_credit  TYPE edo_co21_send_credit_note_requ.
    METHODS convert_currency_debit_note  CHANGING ch_debit   TYPE edo_co21_send_debit_note_reque.
ENDCLASS.



CLASS ZEDOC_ADAPTOR IMPLEMENTATION.


  METHOD if_edoc_adaptor~change_edocument_type.
  ENDMETHOD.


  METHOD if_edoc_adaptor~get_variable_key.
    CLEAR cv_varkey.
    SELECT SINGLE fkart
      INTO cv_varkey
      FROM vbrk
      WHERE vbeln = io_source->mv_source_key.
  ENDMETHOD.


  METHOD if_edoc_adaptor~is_relevant.
  ENDMETHOD.


  METHOD if_edoc_adaptor~set_fix_values.
    DATA ls_fix_value TYPE edoc_fix_value.
    " Add fixed values for DIAN response codes to determine status

    ls_fix_value-fieldvalue = '0'.
    ls_fix_value-fixvaluename = 'EDOSTAT_APPR_CODES'.  "Approved
    APPEND ls_fix_value TO ct_fix_values.

    ls_fix_value-fieldvalue = '00'.
    APPEND ls_fix_value TO ct_fix_values.

    ls_fix_value-fieldvalue = '66'.
    ls_fix_value-fixvaluename = 'EDOSTAT_NOINFO_CODES'.  "No Info
    APPEND ls_fix_value TO ct_fix_values.

    CLEAR ls_fix_value-fieldvalue.
    APPEND ls_fix_value TO ct_fix_values.

    ls_fix_value-fieldvalue = '99'.
    ls_fix_value-fixvaluename = 'EDOSTAT_REJE_CODES'.  "Rejected
    APPEND ls_fix_value TO ct_fix_values.

    ls_fix_value-fieldvalue = '90'.
    APPEND ls_fix_value TO ct_fix_values.
  ENDMETHOD.


  METHOD if_edoc_adaptor~set_output_data.
    DATA: ls_fi_invoice TYPE edoc_src_data_fi_invoice,
          ls_sd_invoice TYPE edoc_src_data_sd_invoice.

    DATA: lwa_invoice_periodo TYPE edo_co21_invoice_period,
          lv_start_date       TYPE sy-datum,
          lv_end_date         TYPE sy-datum,
          lv_month            TYPE fcmnr,
          lv_year             TYPE gjahr.

    CONSTANTS: lco_22 TYPE char2 VALUE '22',
               lco_32 TYPE char2 VALUE '32'.

    FIELD-SYMBOLS: <fs_source_data> TYPE any.

    FIELD-SYMBOLS: <fs_invoice> TYPE edo_co21_send_invoice_request,
                   <fs_credit>  TYPE edo_co21_send_credit_note_requ,
                   <fs_debit>   TYPE edo_co21_send_debit_note_reque.

**********************************************************************
    " Sólo procesar envío de Facturas y notas
    IF iv_interface_id NE 'CO_INVOICE_TRANSM'
     AND iv_interface_id NE 'CO_DEBIT_NOTE_TRANSM'
     AND iv_interface_id NE 'CO_CREDIT_NOTE_TRANSM'.
      EXIT.
    ENDIF.
**********************************************************************

    CASE io_source->mv_source_type.
      WHEN 'FI_INVOICE'.
        ASSIGN ls_fi_invoice TO <fs_source_data>.
        io_source->get_data( IMPORTING es_data = <fs_source_data> ).

        CASE iv_edoc_type.
          WHEN 'CO_SUPPORT'.
            ASSIGN cs_output_data TO <fs_invoice>.
            IF <fs_invoice>-document-invoice-document_currency_code-base-base-content NE 'COP'.
              convert_currency_invoice(
                CHANGING ch_invoice = <fs_invoice> ).
            ENDIF.
          WHEN OTHERS.
        ENDCASE.

      WHEN 'SD_INVOICE'.
        ASSIGN ls_sd_invoice TO <fs_source_data>.
        io_source->get_data( IMPORTING es_data = <fs_source_data> ).

        CASE iv_edoc_type.
          WHEN 'CO_INV'.
            ASSIGN cs_output_data TO <fs_invoice>.
            IF <fs_invoice>-document-invoice-document_currency_code-base-base-content NE 'COP'.
              convert_currency_invoice(
                CHANGING ch_invoice = <fs_invoice> ).
            ENDIF.

          WHEN 'CO_CRE'.
            ASSIGN cs_output_data TO <fs_credit>.
            IF <fs_credit>-document-credit_note-document_currency_code-base-base-content NE 'COP'.
              convert_currency_credit_note(
                CHANGING ch_credit = <fs_credit> ).
            ENDIF.

            IF <fs_credit>-document-credit_note-customization_id-base-base-content = lco_22.
              DATA(lv_fecha) = <fs_credit>-document-credit_note-issue_date-base-content.
              lv_month = lv_fecha+4(2).
              lv_year  = lv_fecha(4).

              CALL FUNCTION 'OIL_MONTH_GET_FIRST_LAST'
                EXPORTING
                  i_month     = lv_month
                  i_year      = lv_year
                IMPORTING
                  e_first_day = lv_start_date
                  e_last_day  = lv_end_date
                EXCEPTIONS
                  wrong_date  = 1
                  OTHERS      = 2.

              IF sy-subrc EQ 0.
              ENDIF.

              lwa_invoice_periodo-start_date-base-content = lv_start_date.
              lwa_invoice_periodo-end_date-base-content   = lv_end_date.
              APPEND lwa_invoice_periodo TO <fs_credit>-document-credit_note-invoice_period.
            ENDIF.

          WHEN 'CO_DEB'.
            ASSIGN cs_output_data TO <fs_debit>.
            IF <fs_debit>-document-debit_note-document_currency_code-base-base-content NE 'COP'.
              convert_currency_debit_note(
                CHANGING ch_debit = <fs_debit> ).
            ENDIF.

            IF <fs_debit>-document-debit_note-customization_id-base-base-content = lco_32.
              lv_fecha = <fs_debit>-document-debit_note-issue_date-base-content.
              lv_month = lv_fecha+4(2).
              lv_year  = lv_fecha(4).

              CALL FUNCTION 'OIL_MONTH_GET_FIRST_LAST'
                EXPORTING
                  i_month     = lv_month
                  i_year      = lv_year
                IMPORTING
                  e_first_day = lv_start_date
                  e_last_day  = lv_end_date
                EXCEPTIONS
                  wrong_date  = 1
                  OTHERS      = 2.

              IF sy-subrc EQ 0.
              ENDIF.

              lwa_invoice_periodo-start_date-base-content = lv_start_date.
              lwa_invoice_periodo-end_date-base-content   = lv_end_date.
              APPEND lwa_invoice_periodo TO <fs_debit>-document-debit_note-invoice_period.
            ENDIF.

          WHEN OTHERS.
        ENDCASE.

      WHEN OTHERS.
    ENDCASE.

  ENDMETHOD.


  METHOD if_edoc_adaptor~set_value_mapping.
  ENDMETHOD.


  METHOD convert_currency_invoice.

    " Declaración de variables
    DATA: lv_kurrf         TYPE kurrf,
          lv_waerk_ext     TYPE waerk,
          lv_base          TYPE wertv12,
          lv_base_2        TYPE wertv12,
          lv_base_5        TYPE wertv12,
          lv_base_6        TYPE wertv12,
          lv_base_7        TYPE wertv12,
          lv_base_8        TYPE wertv12,
          lv_base_9        TYPE wertv12,
          lv_base_11       TYPE wertv12,
          lv_base_12       TYPE wertv12,
          lv_base_13       TYPE wertv12,
          lv_base_15       TYPE wertv12,
          lv_base_16       TYPE wertv12,
          lv_base_17       TYPE wertv12,
          lv_base_18       TYPE wertv12,
          lv_payable_amoun TYPE p LENGTH 8 DECIMALS 3.

    " Declaración de constantes
    CONSTANTS: lco_cop   TYPE char3 VALUE 'COP',
               lco_usd   TYPE char3 VALUE 'USD',
               lco_10000 TYPE char5 VALUE '10000'.

    " Obtención de tasa y moneda
    lv_waerk_ext = ch_invoice-document-invoice-document_currency_code-base-base-content.
    lv_kurrf     = ch_invoice-document-invoice-payment_exchange_rate-calculation_rate-base-base-content.

    " Conversión de moneda de cabecera
    IF ch_invoice-document-invoice-document_currency_code-base-base-content IS NOT INITIAL.
      ch_invoice-document-invoice-document_currency_code-base-base-content = lco_cop.
    ENDIF.

    IF ch_invoice-document-invoice-payment_exchange_rate-source_currency_code-base-base-content IS NOT INITIAL.
      ch_invoice-document-invoice-payment_exchange_rate-source_currency_code-base-base-content = lco_cop.
    ENDIF.

    ch_invoice-document-invoice-payment_exchange_rate-source_currency_base_rate-base-base-content = lco_10000.
    ch_invoice-document-invoice-payment_exchange_rate-target_currency_code-base-base-content = lv_waerk_ext.

    " Procesamiento del total de impuestos
    READ TABLE ch_invoice-document-invoice-tax_total ASSIGNING FIELD-SYMBOL(<lfs_tax_total>) INDEX 1.
    IF <lfs_tax_total> IS ASSIGNED.

      IF <lfs_tax_total>-rounding_amount-base-content IS NOT INITIAL.
        <lfs_tax_total>-rounding_amount-base-currency_id = lco_cop.
        lv_base_16 = <lfs_tax_total>-rounding_amount-base-content * lv_kurrf.
      ENDIF.

      READ TABLE <lfs_tax_total>-tax_subtotal ASSIGNING FIELD-SYMBOL(<lfs_tax_subtotal>) INDEX 1.
      IF <lfs_tax_subtotal> IS ASSIGNED.
        <lfs_tax_subtotal>-taxable_amount-base-currency_id = lco_cop.
        lv_base_2 = <lfs_tax_subtotal>-taxable_amount-base-content * lv_kurrf.
        <lfs_tax_subtotal>-tax_amount-base-currency_id = lco_cop.
        <lfs_tax_total>-tax_amount-base-currency_id = lco_cop.
        lv_base = lv_base_2 * <lfs_tax_subtotal>-tax_category-percent-base-base-content / 100.
      ENDIF.
    ENDIF.

    " Conversión de montos totales
    ch_invoice-document-invoice-legal_monetary_total-line_extension_amount-base-currency_id = lco_cop.
    lv_base_18 = ch_invoice-document-invoice-legal_monetary_total-line_extension_amount-base-content * lv_kurrf.

    ch_invoice-document-invoice-legal_monetary_total-tax_exclusive_amount-base-currency_id = lco_cop.
    lv_base_5 = ch_invoice-document-invoice-legal_monetary_total-tax_exclusive_amount-base-content * lv_kurrf.

    ch_invoice-document-invoice-legal_monetary_total-tax_inclusive_amount-base-currency_id = lco_cop.
    lv_base_6 = lv_base_18 + lv_base.

    ch_invoice-document-invoice-legal_monetary_total-allowance_total_amount-base-currency_id = lco_cop.
    lv_base_7 = ch_invoice-document-invoice-legal_monetary_total-allowance_total_amount-base-content * lv_kurrf.

    ch_invoice-document-invoice-legal_monetary_total-charge_total_amount-base-currency_id = lco_cop.
    lv_base_8 = ch_invoice-document-invoice-legal_monetary_total-charge_total_amount-base-content * lv_kurrf.

    ch_invoice-document-invoice-legal_monetary_total-prepaid_amount-base-currency_id = lco_cop.
    lv_base_9 = ch_invoice-document-invoice-legal_monetary_total-prepaid_amount-base-content * lv_kurrf.

    ch_invoice-document-invoice-legal_monetary_total-payable_amount-base-currency_id = lco_cop.
    lv_payable_amoun = ch_invoice-document-invoice-legal_monetary_total-payable_amount-base-content * lv_kurrf.

    " Loop por líneas de factura
    LOOP AT ch_invoice-document-invoice-invoice_line ASSIGNING FIELD-SYMBOL(<lfs_invoice_line>).

      <lfs_invoice_line>-line_extension_amount-base-currency_id = lco_cop.
      lv_base_11 = <lfs_invoice_line>-line_extension_amount-base-content * lv_kurrf.

      " Procesar impuestos de línea
      READ TABLE <lfs_invoice_line>-tax_total ASSIGNING FIELD-SYMBOL(<lfs_tax_total_2>) INDEX 1.
      IF <lfs_tax_total_2> IS ASSIGNED.

        IF <lfs_tax_total_2>-rounding_amount-base-content IS NOT INITIAL.
          <lfs_tax_total_2>-rounding_amount-base-currency_id = lco_cop.
          lv_base_17 = <lfs_tax_total_2>-rounding_amount-base-content * lv_kurrf.
        ENDIF.

        READ TABLE <lfs_tax_total_2>-tax_subtotal ASSIGNING FIELD-SYMBOL(<lfs_tax_subtotal_2>) INDEX 1.
        IF <lfs_tax_subtotal_2> IS ASSIGNED.
          <lfs_tax_subtotal_2>-taxable_amount-base-currency_id = lco_cop.
          lv_base_13 = <lfs_tax_subtotal_2>-taxable_amount-base-content * lv_kurrf.
          <lfs_tax_subtotal_2>-tax_amount-base-currency_id = lco_cop.
          <lfs_tax_total_2>-tax_amount-base-currency_id = lco_cop.
          lv_base_12 = lv_base_13 * <lfs_tax_subtotal_2>-tax_category-percent-base-base-content / 100.
        ENDIF.
      ENDIF.

      " Pricing Reference
      CLEAR lv_base.
      TRY.
          IF <lfs_invoice_line>-pricing_reference-alternative_condition_price[ 1 ]-price_amount-base-currency_id IS NOT INITIAL.
            <lfs_invoice_line>-pricing_reference-alternative_condition_price[ 1 ]-price_amount-base-currency_id = lco_cop.
          ENDIF.
          lv_base = <lfs_invoice_line>-pricing_reference-alternative_condition_price[ 1 ]-price_amount-base-content * lv_kurrf.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.

      <lfs_invoice_line>-price-price_amount-base-currency_id = lco_cop.
      lv_base_15 = <lfs_invoice_line>-price-price_amount-base-content * lv_kurrf.

    ENDLOOP.

  ENDMETHOD.


  METHOD convert_currency_credit_note.
    "Declaracion de variables
    DATA: lv_referencia TYPE xblnr_v1,
          lv_kurrf      TYPE kurrf,
          lv_waerk_ext  TYPE waerk,
          lv_base       TYPE wertv12,
          lv_base_2     TYPE wertv12,
          lv_base_5     TYPE wertv12,
          lv_base_6     TYPE wertv12,
          lv_base_7     TYPE wertv12,
          lv_base_8     TYPE wertv12,
          lv_base_9     TYPE wertv12,
          lv_base_11    TYPE wertv12,
          lv_base_12    TYPE wertv12,
          lv_base_13    TYPE wertv12,
          lv_base_15    TYPE wertv12,
          lv_base_16    TYPE wertv12,
          lv_base_17    TYPE wertv12,
          lv_start_date TYPE sy-datum,
          lv_end_date   TYPE sy-datum,
          lv_fcmnr      TYPE fcmnr,
          lv_gjahr      TYPE gjahr.

    "Declaracion de constantes
    CONSTANTS: lco_cop         TYPE char3 VALUE 'COP',
               lco_10000       TYPE char5 VALUE '10000',
               lco_22          TYPE char2 VALUE '22',
               lco_scheme_name TYPE string VALUE 'CUFE-SHA384'.

    "Declaracion de estructura
    DATA lwa_invoice_periodo TYPE edo_co21_invoice_period.

    "Obtener datos para conversion
    lv_waerk_ext = ch_credit-document-credit_note-document_currency_code-base-base-content.
    lv_kurrf     = ch_credit-document-credit_note-payment_exchange_rate-calculation_rate-base-base-content.

    "Modificar moneda document currency
    ch_credit-document-credit_note-document_currency_code-base-base-content = lco_cop.

    "Modificar moneda Source currency
    ch_credit-document-credit_note-payment_exchange_rate-source_currency_code-base-base-content = lco_cop.

    "Modificar valor de Source currency base
    ch_credit-document-credit_note-payment_exchange_rate-source_currency_base_rate-base-base-content = lco_10000.

    "Modificar moneda Target currency
    ch_credit-document-credit_note-payment_exchange_rate-target_currency_code-base-base-content = lv_waerk_ext.

    "Obtener info de tax_amount
    READ TABLE ch_credit-document-credit_note-tax_total ASSIGNING FIELD-SYMBOL(<lfs_tax_total>) INDEX 1.
    IF <lfs_tax_total> IS ASSIGNED.
      <lfs_tax_total>-tax_amount-base-currency_id = lco_cop.
      <lfs_tax_total>-rounding_amount-base-currency_id = lco_cop.

      READ TABLE <lfs_tax_total>-tax_subtotal ASSIGNING FIELD-SYMBOL(<lfs_tax_total3>) INDEX 1.
      lv_base = <lfs_tax_total3>-tax_amount-base-content.
      <lfs_tax_total>-tax_amount-base-content = lv_base.

      READ TABLE <lfs_tax_total>-tax_subtotal ASSIGNING FIELD-SYMBOL(<lfs_tax_subtotal>) INDEX 1.
      IF <lfs_tax_subtotal> IS ASSIGNED.
        <lfs_tax_subtotal>-taxable_amount-base-currency_id = lco_cop.
        <lfs_tax_subtotal>-tax_amount-base-currency_id    = lco_cop.
      ENDIF.
    ENDIF.

    "Modificar totales monetarios
    ch_credit-document-credit_note-legal_monetary_total-line_extension_amount-base-currency_id  = lco_cop.
    ch_credit-document-credit_note-legal_monetary_total-tax_exclusive_amount-base-currency_id   = lco_cop.
    ch_credit-document-credit_note-legal_monetary_total-tax_inclusive_amount-base-currency_id   = lco_cop.
    ch_credit-document-credit_note-legal_monetary_total-allowance_total_amount-base-currency_id = lco_cop.
    ch_credit-document-credit_note-legal_monetary_total-charge_total_amount-base-currency_id    = lco_cop.
    ch_credit-document-credit_note-legal_monetary_total-prepaid_amount-base-currency_id         = lco_cop.
    ch_credit-document-credit_note-legal_monetary_total-payable_amount-base-currency_id         = lco_cop.

    "Loop de líneas de nota crédito
    LOOP AT ch_credit-document-credit_note-credit_note_line ASSIGNING FIELD-SYMBOL(<lfs_invoice_line>).
      <lfs_invoice_line>-line_extension_amount-base-currency_id = lco_cop.

      LOOP AT <lfs_invoice_line>-tax_total ASSIGNING FIELD-SYMBOL(<lfs_tax_total_2>).
        <lfs_tax_total_2>-tax_amount-base-currency_id     = lco_cop.
        <lfs_tax_total_2>-rounding_amount-base-currency_id = lco_cop.

        LOOP AT <lfs_tax_total_2>-tax_subtotal ASSIGNING FIELD-SYMBOL(<lfs_tax_subtotal_2>).
          <lfs_tax_subtotal_2>-taxable_amount-base-currency_id = lco_cop.
          <lfs_tax_subtotal_2>-tax_amount-base-currency_id     = lco_cop.
        ENDLOOP.
      ENDLOOP.

      <lfs_invoice_line>-price-price_amount-base-currency_id = lco_cop.
    ENDLOOP.

    "Tomar datos del UUID de la nota crédito
    DATA(lv_scheme_id)          = ch_credit-document-credit_note-uuid-base-base-scheme_id.
    DATA(lv_scheme_agency_id)   = ch_credit-document-credit_note-uuid-base-base-scheme_agency_id.
    DATA(lv_scheme_agency_name) = ch_credit-document-credit_note-uuid-base-base-scheme_agency_name.

    "Llenar datos del UUID de la factura referenciada
    READ TABLE ch_credit-document-credit_note-billing_reference ASSIGNING FIELD-SYMBOL(<lfs_Bref>) INDEX 1.
    IF <lfs_Bref> IS ASSIGNED.
      <lfs_Bref>-invoice_document_reference-uuid-base-base-scheme_id          = lv_scheme_id.
      <lfs_Bref>-invoice_document_reference-uuid-base-base-scheme_name        = lco_scheme_name.
      <lfs_Bref>-invoice_document_reference-uuid-base-base-scheme_agency_id   = lv_scheme_agency_id.
      <lfs_Bref>-invoice_document_reference-uuid-base-base-scheme_agency_name = lv_scheme_agency_name.
    ENDIF.

  ENDMETHOD.


  METHOD convert_currency_debit_note.
    "Declaracion de variables
    DATA: lv_referencia TYPE xblnr_v1,
          lv_kurrf      TYPE kurrf,
          lv_waerk_ext  TYPE waerk,
          lv_base       TYPE wertv12,
          lv_base_2     TYPE wertv12,
          lv_base_5     TYPE wertv12,
          lv_base_6     TYPE wertv12,
          lv_base_7     TYPE wertv12,
          lv_base_8     TYPE wertv12,
          lv_base_9     TYPE wertv12,
          lv_base_11    TYPE wertv12,
          lv_base_12    TYPE wertv12,
          lv_base_13    TYPE wertv12,
          lv_base_15    TYPE wertv12,
          lv_base_16    TYPE wertv12,
          lv_base_17    TYPE wertv12,
          lv_start_date TYPE sy-datum,
          lv_end_date   TYPE sy-datum,
          lv_fcmnr      TYPE fcmnr,
          lv_gjahr      TYPE gjahr.

    "Declaracion de constantes
    CONSTANTS: lco_cop         TYPE char3 VALUE 'COP',
               lco_10000       TYPE char5 VALUE '10000',
               lco_22          TYPE char2 VALUE '22',
               lco_scheme_name TYPE string VALUE 'CUFE-SHA384'.

    "Declaracion de estructura
    DATA lwa_invoice_periodo TYPE edo_co21_invoice_period.

    "Obtener datos para conversion
    lv_waerk_ext = ch_debit-document-debit_note-document_currency_code-base-base-content.
    lv_kurrf     = ch_debit-document-debit_note-payment_exchange_rate-calculation_rate-base-base-content.

    "Modificar moneda document currency
    ch_debit-document-debit_note-document_currency_code-base-base-content = lco_cop.

    "Modificar moneda Source currency
    ch_debit-document-debit_note-payment_exchange_rate-source_currency_code-base-base-content = lco_cop.

    "Modificar valor de Source currency base
    ch_debit-document-debit_note-payment_exchange_rate-source_currency_base_rate-base-base-content = lco_10000.

    "Modificar moneda Target currency
    ch_debit-document-debit_note-payment_exchange_rate-target_currency_code-base-base-content = lv_waerk_ext.

    "Obtener info de tax_amount
    READ TABLE ch_debit-document-debit_note-tax_total ASSIGNING FIELD-SYMBOL(<lfs_tax_total>) INDEX 1.
    IF <lfs_tax_total> IS ASSIGNED.
      <lfs_tax_total>-tax_amount-base-currency_id = lco_cop.
      <lfs_tax_total>-rounding_amount-base-currency_id = lco_cop.

      READ TABLE <lfs_tax_total>-tax_subtotal ASSIGNING FIELD-SYMBOL(<lfs_tax_total3>) INDEX 1.
      lv_base = <lfs_tax_total3>-tax_amount-base-content.
      <lfs_tax_total>-tax_amount-base-content = lv_base.

      READ TABLE <lfs_tax_total>-tax_subtotal ASSIGNING FIELD-SYMBOL(<lfs_tax_subtotal>) INDEX 1.
      IF <lfs_tax_subtotal> IS ASSIGNED.
        <lfs_tax_subtotal>-taxable_amount-base-currency_id = lco_cop.
        <lfs_tax_subtotal>-tax_amount-base-currency_id    = lco_cop.
      ENDIF.
    ENDIF.

    "Modificar totales monetarios
    ch_debit-document-debit_note-requested_monetary_total-line_extension_amount-base-currency_id  = lco_cop.
    ch_debit-document-debit_note-requested_monetary_total-tax_exclusive_amount-base-currency_id   = lco_cop.
    ch_debit-document-debit_note-requested_monetary_total-tax_inclusive_amount-base-currency_id   = lco_cop.
    ch_debit-document-debit_note-requested_monetary_total-allowance_total_amount-base-currency_id = lco_cop.
    ch_debit-document-debit_note-requested_monetary_total-charge_total_amount-base-currency_id    = lco_cop.
    ch_debit-document-debit_note-requested_monetary_total-prepaid_amount-base-currency_id         = lco_cop.
    ch_debit-document-debit_note-requested_monetary_total-payable_amount-base-currency_id         = lco_cop.

    "Loop de líneas de nota débito
    LOOP AT ch_debit-document-debit_note-debit_note_line ASSIGNING FIELD-SYMBOL(<lfs_invoice_line>).
      <lfs_invoice_line>-line_extension_amount-base-currency_id = lco_cop.

      LOOP AT <lfs_invoice_line>-tax_total ASSIGNING FIELD-SYMBOL(<lfs_tax_total_2>).
        <lfs_tax_total_2>-tax_amount-base-currency_id     = lco_cop.
        <lfs_tax_total_2>-rounding_amount-base-currency_id = lco_cop.

        LOOP AT <lfs_tax_total_2>-tax_subtotal ASSIGNING FIELD-SYMBOL(<lfs_tax_subtotal_2>).
          <lfs_tax_subtotal_2>-taxable_amount-base-currency_id = lco_cop.
          <lfs_tax_subtotal_2>-tax_amount-base-currency_id     = lco_cop.
        ENDLOOP.
      ENDLOOP.

      <lfs_invoice_line>-price-price_amount-base-currency_id = lco_cop.
    ENDLOOP.

    "Tomar datos del UUID de la nota débito
    DATA(lv_scheme_id)          = ch_debit-document-debit_note-uuid-base-base-scheme_id.
    DATA(lv_scheme_agency_id)   = ch_debit-document-debit_note-uuid-base-base-scheme_agency_id.
    DATA(lv_scheme_agency_name) = ch_debit-document-debit_note-uuid-base-base-scheme_agency_name.

    "Llenar datos del UUID de la factura referenciada
    READ TABLE ch_debit-document-debit_note-billing_reference ASSIGNING FIELD-SYMBOL(<lfs_Bref>) INDEX 1.
    IF <lfs_Bref> IS ASSIGNED.
      <lfs_Bref>-invoice_document_reference-uuid-base-base-scheme_id          = lv_scheme_id.
      <lfs_Bref>-invoice_document_reference-uuid-base-base-scheme_name        = lco_scheme_name.
      <lfs_Bref>-invoice_document_reference-uuid-base-base-scheme_agency_id   = lv_scheme_agency_id.
      <lfs_Bref>-invoice_document_reference-uuid-base-base-scheme_agency_name = lv_scheme_agency_name.
    ENDIF.

  ENDMETHOD.


  METHOD if_edoc_adaptor~change_form.
  ENDMETHOD.


  METHOD if_edoc_adaptor~restrict_cancel.
  ENDMETHOD.
ENDCLASS.
