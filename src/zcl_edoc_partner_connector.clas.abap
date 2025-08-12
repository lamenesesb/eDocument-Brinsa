class ZCL_EDOC_PARTNER_CONNECTOR definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EDOC_PARTNER_CONNECTOR .
protected section.
private section.

  methods CREATE_PDF
    importing
      !IS_EDOCUMENT type EDOCUMENT
    returning
      value(RET_PDF) type FPCONTENT .

ENDCLASS.



CLASS ZCL_EDOC_PARTNER_CONNECTOR IMPLEMENTATION.


  METHOD create_pdf.

  DATA: ls_outputparams TYPE sfpoutputparams,
          ls_docparams    TYPE sfpdocparams,
          lv_form         TYPE tdsfname,
          lv_fm_name      TYPE rs38l_fnam,
          ls_pdf_file     TYPE fpformoutput,
          lv_vbeln        TYPE vbrk-vbeln.

    DATA ls_interface               TYPE invoice_s_prt_interface.

    CONSTANTS:
      gc_true     TYPE char1 VALUE 'X'.

    DATA(lo_invoice_data) = NEW zcl_sd_invoice_data(  ).

    CLEAR lv_form.

    lv_vbeln = is_edocument-source_key.

    lo_invoice_data->get_cls_form(
      EXPORTING
        i_vbeln = lv_vbeln                 " NÃºmero de documento comercial
      IMPORTING
        e_sfonam = lv_form                 " Nombre del formulario
    ).

    IF lv_form IS NOT INITIAL.

      ls_interface = lo_invoice_data->get_print_data(
                       iv_vbeln = lv_vbeln                 " Documento de facturaciÃ³n
*                     is_nast  =                  " Status de mensajes
                     ) .

      ls_outputparams-getpdf = gc_true.
*      ls_outputparams-noprint   = gc_true.
*      ls_outputparams-nopributt = gc_true.
      ls_outputparams-noarchive = gc_true.
      ls_outputparams-nodialog  = gc_true.

      TRY.

          CALL FUNCTION 'FP_JOB_OPEN'
            CHANGING
              ie_outputparams = ls_outputparams
            EXCEPTIONS
              cancel          = 1
              usage_error     = 2
              system_error    = 3
              internal_error  = 4
              OTHERS          = 5.
          CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
            EXPORTING
              i_name     = lv_form
            IMPORTING
              e_funcname = lv_fm_name.

          CALL FUNCTION lv_fm_name
            EXPORTING
              /1bcdwb/docparams  = ls_docparams
              bil_prt_com        = ls_interface
            IMPORTING
              /1bcdwb/formoutput = ls_pdf_file
            EXCEPTIONS
              usage_error        = 1
              system_error       = 2
              internal_error     = 3
              OTHERS             = 4.

          CALL FUNCTION 'FP_JOB_CLOSE'
            EXCEPTIONS
              usage_error    = 1
              system_error   = 2
              internal_error = 3
              OTHERS         = 4.

        CATCH cx_root.

      ENDTRY.

    ENDIF.

    ret_pdf = ls_pdf_file-pdf.

**    BREAK consultorab2.

    DATA: gs_joboutput    TYPE sfpjoboutput.
*       ls_outputpa<rams TYPE sfpoutputparams,.
*CHECK 1 = 2.

*    SELECT * INTO TABLE @DATA(lt_det)
*      FROM ztwm_detalles
*      WHERE vbeln_f = @lv_vbeln.
*
*
*    IF sy-subrc EQ 0.
*
*      READ TABLE lt_det INTO DATA(wa_det) INDEX 1.
*
*      SELECT SINGLE imprsap INTO @DATA(wl_impres)
*        FROM  zimp_iwm031_5
*      WHERE banda = @wa_det-banda.
*
*
*      CHECK wl_impres IS NOT INITIAL.
**  ls_outputparams-getpdf = gc_true.
*      ls_outputparams-noprint   = gc_true.
**  ls_outputparams-nopributt = gc_true.
*      ls_outputparams-noarchive = gc_true.
*      ls_outputparams-nodialog  = gc_true.
*      ls_outputparams-dest  = wl_impres.
*      ls_outputparams-reqimm  = 'X'.
*
*      CALL FUNCTION 'FP_JOB_OPEN'
*        CHANGING
*          ie_outputparams = ls_outputparams
*        EXCEPTIONS
*          cancel          = 1
*          usage_error     = 2
*          system_error    = 3
*          internal_error  = 4
*          OTHERS          = 5.
*
*
*      CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
*        EXPORTING
*          i_name     = lv_form
*        IMPORTING
*          e_funcname = lv_fm_name.
*
*      CALL FUNCTION lv_fm_name
*        EXPORTING
*          /1bcdwb/docparams  = ls_docparams
*          bil_prt_com        = ls_interface
*        IMPORTING
*          /1bcdwb/formoutput = ls_pdf_file
*        EXCEPTIONS
*          usage_error        = 1
*          system_error       = 2
*          internal_error     = 3
*          OTHERS             = 4.
*
*
*      CALL FUNCTION 'FP_JOB_CLOSE'
*        IMPORTING
*          e_result       = gs_joboutput
*        EXCEPTIONS
*          usage_error    = 1
*          system_error   = 2
*          internal_error = 3
*          OTHERS         = 4.
*
*      DATA: total_pages TYPE fppagecount.
*      DATA: size TYPE i.
*      DATA: total_size TYPE i.
*      DATA: spoolid TYPE rspoid.
*      DATA: copies TYPE rspocopies.
*      DATA: lifetime.
*      size = xstrlen( ls_pdf_file-pdf ).
*      ADD size TO total_size.
*      copies = ls_outputparams-copies.   " gs_joboutput-remaining_pages.
*      lifetime = ls_outputparams-lifetime.
*      total_pages   = gs_joboutput-remaining_pages.
*
*      CALL FUNCTION 'ADS_CREATE_PDF_SPOOLJOB'
*        EXPORTING
*          dest              = ls_outputparams-dest
*          pages             = total_pages
*          pdf_data          = ls_pdf_file-pdf
*          name              = ls_outputparams-dataset
*          suffix1           = ls_outputparams-suffix1
*          suffix2           = ls_outputparams-suffix2
*          copies            = copies
**         PRIO              = ps_op-
*          immediate_print   = ls_outputparams-reqimm
*          auto_delete       = ls_outputparams-reqdel
*          titleline         = ls_outputparams-covtitle
*          receiver          = ls_outputparams-receiver
*          division          = ls_outputparams-division
*          authority         = ls_outputparams-authority
*          lifetime          = lifetime
*        IMPORTING
*          spoolid           = spoolid
*        EXCEPTIONS
*          no_data           = 1
*          not_pdf           = 2
*          wrong_devtype     = 3
*          operation_failed  = 4
*          cannot_write_file = 5
*          device_missing    = 6
*          no_such_device    = 7
*          OTHERS            = 8.
*
*    ENDIF.


  ENDMETHOD.


  METHOD if_edoc_partner_connector~change_email_to_customer.
     DATA: lo_edoc_db         TYPE REF TO if_edocument_db,
          lo_edoc_config_db  TYPE REF TO if_edoc_config_db,
          lo_abap_zip        TYPE REF TO cl_abap_zip,
          lt_edocumentfile   TYPE STANDARD TABLE OF edocumentfile,
          ls_attachments     TYPE edoc_email_attachment,
          ls_attachdoc       TYPE edocumentfile,
          ls_edosrctype_text TYPE edosrctypet,
          lv_attachm_size    TYPE so_obj_len,
          lv_zip_file        TYPE xstring,
          lv_file_name       TYPE string,
          lv_attachdoc_id    TYPE string,
          lv_company_id      TYPE string,
          lv_pdf             TYPE fpcontent,
          lv_email_language  TYPE so_obj_la.

    CONSTANTS: lc_attacheddocument TYPE string     VALUE 'AttachedDocument',
               lc_zip              TYPE string     VALUE 'ZIP',
               lc_attachdoc_id     TYPE string     VALUE '/AttachedDocument/cbc:ID',
               lc_attached         TYPE edoc_file_type VALUE 'ATTACHED'.

    lv_pdf = create_pdf( is_edocument = is_edocument ).

    IF lv_pdf IS NOT INITIAL.
      REFRESH ct_email_attachments.

*   Get eDocument DB handler. Allows using stub with Unit Test
      CREATE OBJECT lo_edoc_db TYPE cl_edocument_db.

      lt_edocumentfile = lo_edoc_db->select_edocumentfile_tab( iv_edoc_guid =  is_edocument-edoc_guid ).

      SORT lt_edocumentfile BY create_date DESCENDING create_time DESCENDING.

      CLEAR ls_attachdoc.
      LOOP AT lt_edocumentfile INTO ls_attachdoc WHERE file_type = lc_attached.
        EXIT.
      ENDLOOP.

      CREATE OBJECT lo_abap_zip.

      IF ls_attachdoc-file_raw IS NOT INITIAL.


        cl_edoc_util_co_ubl_21=>get_value_from_xml(
         EXPORTING
           iv_xml            = ls_attachdoc-file_raw
           iv_value_name     = lc_attachdoc_id
         RECEIVING
           rv_value          = lv_attachdoc_id
        ).

        lv_file_name = cl_edocument_co_ubl_21=>build_attachdoc_filename(
                         iv_nit = lv_company_id
                         iv_id  = lv_attachdoc_id
                       ).
        lo_abap_zip->add(
          EXPORTING
            name           = lv_file_name
            content        = ls_attachdoc-file_raw
        ).
      ENDIF.

      CREATE OBJECT lo_edoc_config_db TYPE cl_edoc_config_db.

      lv_email_language = sy-langu.

      lo_edoc_config_db->select_edosrctypet(
        EXPORTING
          iv_source_type = is_edocument-source_type
          iv_spras = lv_email_language
         RECEIVING
            rs_edosrctypet = ls_edosrctype_text ).

      CONCATENATE ls_edosrctype_text-description is_edocument-source_key
      INTO lv_file_name SEPARATED BY space.

      CONCATENATE lv_file_name '.PDF'  INTO lv_file_name.

      IF lv_pdf IS NOT INITIAL.
        lo_abap_zip->add(
          EXPORTING
            name           = lv_file_name
            content        = lv_pdf
        ).
      ENDIF.

      lv_zip_file = lo_abap_zip->save( ).
      ls_attachments-attachm_subject = lc_attacheddocument.
      ls_attachments-attachm_type = lc_zip.
      ls_attachments-content_hex = cl_document_bcs=>xstring_to_solix( lv_zip_file ).

      lv_attachm_size = xstrlen( lv_zip_file ).
      ls_attachments-attachm_size = lv_attachm_size.
      APPEND ls_attachments TO ct_email_attachments.

    ENDIF.

  ENDMETHOD.


  METHOD if_edoc_partner_connector~trigger.
    IF iv_process_step EQ 'SENDTOCUST'.
      TRY.
          CALL METHOD io_edocument->send_email_to_cust.

          IF sy-subrc EQ 0.
            ev_sent_ok = abap_true.
          ELSE.
            ev_sent_ok = abap_false.
          ENDIF.

        CATCH cx_edocument.
          ev_sent_ok = abap_false.
      ENDTRY.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
