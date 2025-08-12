class ZCL_SD_INVOICE_DATA definition
  public
  final
  create public .

public section.

  methods GET_PRINT_DATA
    importing
      !IV_VBELN type VBELN_VF
      !IS_NAST type NAST optional
    returning
      value(RETURN_DATA) type INVOICE_S_PRT_INTERFACE .
  methods GET_CLS_FORM
    importing
      !I_VBELN type VBELN
    exporting
      !E_SFONAM type NA_FNAME .
protected section.

  data GS_INTERFACE type INVOICE_S_PRT_INTERFACE .
  data GS_VBDKR type VBDKR .
  constants GC_PR_KAPPL type CHAR1 value 'V' ##NO_TEXT.
  constants GC_TRUE type CHAR1 value 'X' ##NO_TEXT.
  constants GC_FALSE type CHAR1 value SPACE ##NO_TEXT.
  constants GC_ENGLISH type CHAR1 value 'E' ##NO_TEXT.
  constants GC_PDF type CHAR1 value '2' ##NO_TEXT.
  constants GC_EQUAL type CHAR2 value 'EQ' ##NO_TEXT.
  constants GC_INCLUDE type CHAR1 value 'I' ##NO_TEXT.

  methods GET_ITEM_DETAILS
    importing
      !IT_VBDPR type TBL_VBDPR .
  methods GET_ITEM_PRICES
    changing
      !CS_ITEM_DETAIL type INVOICE_S_PRT_ITEM_DETAIL .
private section.

  data:
    GT_VBTYP_FIX_VALUES TYPE TABLE OF dd07v .
  data:
    GT_KOMV TYPE TABLE OF komv .
  data GS_KOMK type KOMK .
  data GV_PRICE_PRINT_MODE type CHAR1 .
  data GV_LANGUAGE type SYLANGU .
ENDCLASS.



CLASS ZCL_SD_INVOICE_DATA IMPLEMENTATION.


  METHOD get_cls_form.

    SELECT SINGLE t~sform INTO e_sfonam
    FROM vbrk AS v
     INNER JOIN b011 AS b ON   v~fkart EQ b~fkart
     INNER JOIN tnapr AS t ON  t~kschl EQ b~kschl
   WHERE v~vbeln EQ i_vbeln
     AND b~kappl EQ 'V3'
     AND t~nacha EQ '1'
     AND b~kschl LIKE 'Z%'.
  ENDMETHOD.


  METHOD get_item_details.
    DATA: ls_dd07v       TYPE dd07v,
          ls_text        TYPE tline,
          ls_item_detail TYPE invoice_s_prt_item_detail.

    FIELD-SYMBOLS:
      <ls_vbdpr>       TYPE vbdpr,
      <ls_item_detail> TYPE invoice_s_prt_item_detail.

    CALL FUNCTION 'DD_DOMVALUES_GET'
      EXPORTING
        domname        = 'VBTYPL'
        text           = gc_true
        langu          = gv_language
      TABLES
        dd07v_tab      = gt_vbtyp_fix_values
      EXCEPTIONS
        wrong_textflag = 1
        OTHERS         = 2.

    IF sy-subrc <> 0.

    ENDIF.

    LOOP AT it_vbdpr ASSIGNING <ls_vbdpr>.

      CLEAR ls_item_detail.

*   Clearing items (Verrechnungspositionen) will be printed only in
*   down payment requests
      IF ( gs_vbdkr-fktyp EQ 'P'  )
      OR    ( gs_vbdkr-fktyp NE 'P'
      AND     <ls_vbdpr>-fareg NA '45' ).

*--- Fill the VBDPR structure
        ls_item_detail-vbdpr = <ls_vbdpr>.

*--- Get the type text of the reference document
        IF
NOT ls_item_detail-vbdpr-vbeln_vg2 IS INITIAL.
          READ TABLE gt_vbtyp_fix_values  INTO ls_dd07v
                    WITH KEY domvalue_l = ls_item_detail-vbdpr-vgtyp.

          IF sy-subrc IS INITIAL.
            ls_item_detail-vgtyp_text = ls_dd07v-ddtext.
          ENDIF.
        ENDIF.

*--- Get the item prices
        get_item_prices(
          CHANGING
            cs_item_detail = ls_item_detail                 " Items Detail for PDF Print
            ).
*Get configurations
*      perform get_item_characteristics     changing ls_item_detail.
*      if <gv_returncode> <> 0.
*        return.
*      endif.

        APPEND ls_item_detail TO gs_interface-item_detail.

      ELSEIF ( gs_vbdkr-fktyp NE 'P'
      AND      <ls_vbdpr>-fareg CA '45' ).
*--- Get downpayment data
*      perform get_item_downpayment         using <ls_vbdpr>.
*      if <gv_returncode> <> 0.
*        return.
*      endif.
      ENDIF.

    ENDLOOP.             " Items Detail for PDF Print
  ENDMETHOD.


  METHOD get_item_prices.
    DATA: ls_komp  TYPE komp,
          ls_komvd TYPE komvd,
          lv_lines TYPE i.

    DATA: ro_print     TYPE REF TO cl_tm_invoice,
          lv_sim_flag  TYPE boolean,
          lt_tax_items TYPE komvd_t,
          ls_tax_items TYPE komvd,
          ls_komv      TYPE komv.

*--- Fill the communication structure
    IF gs_komk-knumv NE gs_vbdkr-knumv OR
       gs_komk-knumv IS INITIAL.
      CLEAR gs_komk.
      gs_komk-mandt     = sy-mandt.
      gs_komk-fkart     = gs_vbdkr-fkart.
      gs_komk-kalsm     = gs_vbdkr-kalsm.
      gs_komk-kappl     = gc_pr_kappl.
      gs_komk-waerk     = gs_vbdkr-waerk.
      gs_komk-knumv     = gs_vbdkr-knumv.
      gs_komk-knuma     = gs_vbdkr-knuma.
      gs_komk-vbtyp     = gs_vbdkr-vbtyp.
      gs_komk-land1     = gs_vbdkr-land1.
      gs_komk-vkorg     = gs_vbdkr-vkorg.
      gs_komk-vtweg     = gs_vbdkr-vtweg.
      gs_komk-spart     = gs_vbdkr-spart.
      gs_komk-bukrs     = gs_vbdkr-bukrs.
      gs_komk-hwaer     = gs_vbdkr-waers.
      gs_komk-prsdt     = gs_vbdkr-erdat.
      gs_komk-kurst     = gs_vbdkr-kurst.
      gs_komk-kurrf     = gs_vbdkr-kurrf.
      gs_komk-kurrf_dat = gs_vbdkr-kurrf_dat.
    ENDIF.
    ls_komp-kposn     = cs_item_detail-vbdpr-posnr.
    ls_komp-kursk     = cs_item_detail-vbdpr-kursk.
    ls_komp-kursk_dat = cs_item_detail-vbdpr-kursk_dat.
    IF cl_sd_doc_category_util=>is_any_retour( gs_vbdkr-vbtyp ).
      IF cs_item_detail-vbdpr-shkzg CA ' A'.
        ls_komp-shkzg = gc_true.
      ENDIF.
    ELSE.
      IF cs_item_detail-vbdpr-shkzg CA 'BX'.
        ls_komp-shkzg = gc_true.
      ENDIF.
    ENDIF.


*--- Get the item prices
* ERP TM Integration
    IF cl_ops_switch_check=>aci_sfws_sc_erptms_ii( ) EQ abap_true.
      IF gv_price_print_mode EQ 'A'.
        CALL FUNCTION 'RV_PRICE_PRINT_ITEM'
          EXPORTING
            comm_head_i = gs_komk
            comm_item_i = ls_komp
            language    = gv_language
          IMPORTING
            comm_head_e = gs_komk
            comm_item_e = ls_komp
          TABLES
            tkomv       = gt_komv
            tkomvd      = cs_item_detail-conditions.
      ELSE.
        CALL FUNCTION 'RV_PRICE_PRINT_ITEM_BUFFER'
          EXPORTING
            comm_head_i = gs_komk
            comm_item_i = ls_komp
            language    = gv_language
          IMPORTING
            comm_head_e = gs_komk
            comm_item_e = ls_komp
          TABLES
            tkomv       = gt_komv
            tkomvd      = cs_item_detail-conditions.
      ENDIF.
    ELSE.
      IF gv_price_print_mode EQ 'A'.
        CALL FUNCTION 'RV_PRICE_PRINT_ITEM'
          EXPORTING
            comm_head_i = gs_komk
            comm_item_i = ls_komp
            language    = gv_language
          IMPORTING
            comm_head_e = gs_komk
            comm_item_e = ls_komp
          TABLES
            tkomv       = gt_komv
            tkomvd      = cs_item_detail-conditions.
      ELSE.
        CALL FUNCTION 'RV_PRICE_PRINT_ITEM_BUFFER'
          EXPORTING
            comm_head_i = gs_komk
            comm_item_i = ls_komp
            language    = gv_language
          IMPORTING
            comm_head_e = gs_komk
            comm_item_e = ls_komp
          TABLES
            tkomv       = gt_komv
            tkomvd      = cs_item_detail-conditions.
      ENDIF.
    ENDIF.

    IF NOT cs_item_detail-conditions IS INITIAL.
*   The conditions have always one initial line
      DESCRIBE TABLE cs_item_detail-conditions LINES lv_lines.
      IF lv_lines EQ 1.
        READ TABLE cs_item_detail-conditions INTO ls_komvd
                                             INDEX 1.
        IF NOT ls_komvd IS INITIAL.
          cs_item_detail-ex_conditions = gc_true.
        ENDIF.
      ELSE.
        cs_item_detail-ex_conditions = gc_true.
      ENDIF.
    ENDIF.

*--- Fill the tax code
    CALL FUNCTION 'SD_TAX_CODE_MAINTAIN'
      EXPORTING
        key_knumv           = gs_komk-knumv
        key_kposn           = ls_komp-kposn
        i_application       = ' '
        i_pricing_procedure = gs_komk-kalsm
      TABLES
        xkomv               = gt_komv.
  ENDMETHOD.


  METHOD get_print_data.
    DATA: ls_comwa TYPE vbco3,
          lt_vbdpr TYPE tbl_vbdpr.

    ls_comwa-mandt = sy-mandt.

    IF is_nast IS NOT INITIAL.
      ls_comwa-spras = is_nast-spras.
      ls_comwa-kunde = is_nast-parnr.
      ls_comwa-parvw = is_nast-parvw.
    ELSE.
      ls_comwa-parvw = 'RE'.
      ls_comwa-spras = sy-langu. "GTCU 03/01/2025
    ENDIF.

    ls_comwa-vbeln = iv_vbeln.
    CALL FUNCTION 'RV_BILLING_PRINT_VIEW'
      EXPORTING
        comwa                        = ls_comwa
      IMPORTING
        kopf                         = gs_interface-head_detail-vbdkr
      TABLES
        pos                          = lt_vbdpr
      EXCEPTIONS
        terms_of_payment_not_in_t052 = 1
        error_message                = 2
        OTHERS                       = 3.

    gs_vbdkr = gs_interface-head_detail-vbdkr.

*--- Set default language
    IF is_nast IS NOT INITIAL.
      gv_language = is_nast-spras.
    ELSE.
      gv_language = sy-langu.
    ENDIF.

*--- Get the item details
    get_item_details( it_vbdpr = lt_vbdpr ).

    return_data = gs_interface.
  ENDMETHOD.
ENDCLASS.
