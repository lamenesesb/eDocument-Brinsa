class ZCL_EDOCUMENT_CO_AIF_CONNECTOR definition
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
      !ER_DATA type ref to DATA
    raising
      CX_EDOCUMENT .
protected section.
private section.
ENDCLASS.



CLASS ZCL_EDOCUMENT_CO_AIF_CONNECTOR IMPLEMENTATION.


  method IF_EDOC_INTERFACE_CONNECTOR~CANCEL.
    INCLUDE EDOC_AIF_PROXY_CANCEL.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~COMMUNICATE_ACTION.
    INCLUDE EDOC_AIF_PROXY_COMMUNICATE.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~DISPLAY_EDOCUMENT.
    INCLUDE EDOC_AIF_PROXY_CO_DISPLAY.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~NAVIGATE_TO_MONITOR.
    INCLUDE EDOC_AIF_PROXY_CO_NAVIGATE.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~PULL_REQUEST.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~RESUBMIT.
  endmethod.


  method IF_EDOC_INTERFACE_CONNECTOR~TRIGGER.
    INCLUDE EDOC_AIF_PROXY_CO_TRIGGER.
  endmethod.


  method MAP_DATA.
    INCLUDE EDOC_AIF_PROXY_CO_MAP_DATA.
  endmethod.
ENDCLASS.
