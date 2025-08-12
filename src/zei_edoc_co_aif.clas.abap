class ZEI_EDOC_CO_AIF definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EDOC_INTERFACE_CONNECTOR .

  types:
    BEGIN OF ty_comm_action,
        interface_guid TYPE edoc_interface_guid,
        process_step   TYPE edoc_process_step,
      END OF ty_comm_action .
  types:
    ty_comm_action_tab TYPE STANDARD TABLE OF ty_comm_action .

  class-data GT_COMM_ACTION type TY_COMM_ACTION_TAB .
  methods MAP_DATA
    importing
      !IR_DATA type ref to DATA optional
      !IV_PROCESS_STEP type EDOC_PROCESS_STEP optional
      !IV_PROCESS type EDOC_PROCESS optional
      !IV_PROCESS_VER type EDOC_PROCESS_VERSION optional
    exporting
      !ER_DATA type ref to DATA .

protected section.

private section.
ENDCLASS.



CLASS ZEI_EDOC_CO_AIF IMPLEMENTATION.


  method IF_EDOC_INTERFACE_CONNECTOR~CANCEL.
    INCLUDE edoc_aif_proxy_cancel.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~CLEAN_UP_MESSAGES.
    INCLUDE edoc_intf_conn_co_cleanup_mess.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~COMMUNICATE_ACTION.
    INCLUDE edoc_aif_proxy_communicate.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~DISPLAY_EDOCUMENT.
    INCLUDE edoc_aif_proxy_co_display.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~NAVIGATE_TO_MONITOR.
    INCLUDE edoc_aif_proxy_co_navigate.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~PREPARE_MESSAGES.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~PULL_MESSAGES.
    INCLUDE edoc_intf_conn_co_pull_msg.
  endmethod.


  METHOD if_edoc_interface_connector~trigger.

    FIELD-SYMBOLS <fs_vbrk> TYPE edoc_vbrkvb.
    DATA lti_vbrk TYPE STANDARD TABLE OF vbrk.
    DATA lwa_vbrk TYPE vbrk.

    INCLUDE edoc_aif_proxy_co_trigger.

    IF iv_interface_id = 'CO_INVOICE_TRANSM'.

      ASSIGN COMPONENT 'VBRK' OF STRUCTURE <ls_source_structure> TO <fs_vbrk>.

      CALL FUNCTION 'ZFM_WM_I031_6_FACTURA'
        STARTING NEW TASK 'TASK_I031_6_FAC'
        EXPORTING
          iv_factura = <fs_vbrk>-vbeln
          iv_xblnr   = <fs_vbrk>-xblnr.

      MOVE-CORRESPONDING <fs_vbrk> TO lwa_vbrk.
      APPEND lwa_vbrk TO lti_vbrk.

      CALL FUNCTION 'ZFM_SD_I001_6'
        STARTING NEW TASK 'TASK_SD_I001_6'
        EXPORTING
          i_t_vbrk = lti_vbrk.

    ENDIF.



  ENDMETHOD.


  method MAP_DATA.
    INCLUDE edoc_aif_proxy_co_map_data.
  endmethod.
ENDCLASS.
