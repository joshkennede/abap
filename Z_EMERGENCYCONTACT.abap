*----------------------------------------------------------------------*
* Program                : Z_EMERGENCYCONTACT                          *
* Created on             : 12.14.2016                                  *
* Created by             : J. Kennedy                                  *
* Developer              : J. Kennedy                                  *
* Technical  Designer    : J. Kennedy                                  *
* Functional Designer    : J. Kennedy                                  *
* Change/Transport Number: Local Object                                *
* Report Description     : Z_EMERGENCYCONTACT                          *
*----------------------------------------------------------------------*
*        MODIFICATION LOG                                              *
*----------------------------------------------------------------------*
* CTS #       Date        Modified by                                  *
*                         Description                                  *
* ==========  ==========  =======================                      *
* 1.0         12.14.16    Initial Development                          *
* 2.0         02.28.17    Added Business Area logic + selection screen *
*                         Fixes to logic around blank phone #          *
*                                                                      *
*                                                                      *
*----------------------------------------------------------------------*

REPORT Z_EMERGENCYCONTACT
        LINE-SIZE 255
        LINE-COUNT 65(2)
        NO STANDARD PAGE HEADING
        MESSAGE-ID zhr_reports.

INCLUDE zhi_alv_common_utils.   "This is a must for ALV Based Report
*----------------------------------------------------------------------*
* Data Definitions                                                     *
*----------------------------------------------------------------------*
* Tables - Database Tables                                             *
*----------------------------------------------------------------------*

TABLES: pa0001,
        pa0002,
        pa0021,
        pa0106,
        tgsbt.

*********************************************************
* GENERIC DATA                                          *
*********************************************************

* Structure for all data to be processed

TYPES: BEGIN OF t_input,
        pernr     LIKE pa0001-pernr,    "Personnel Number
        nachn     LIKE pa0002-nachn,    "Last name
        vorna     LIKE pa0002-vorna,    "First name
        gsber     LIKE pa0001-gsber,    "Business Area
        gtext     LIKE tgsbt-gtext,     "Business Area Text
        begda     LIKE pa0001-begda,    "Begin Date
        endda     LIKE pa0001-endda,    "End Date
        favor     LIKE pa0021-favor,    "Emergency Contact fName
        fanam     LIKE pa0021-fanam,    "Emergency Contact lName
        telnr     LIKE pa0106-telnr,    "Emergency Contact pNumber
       END OF t_input.

DATA:  itab_input TYPE STANDARD TABLE OF t_input,
       wa_input   TYPE t_input.


* For ALV to Show data - The final output table should be called itab_output.
* And it should be defined by type t_output.

TYPES: BEGIN OF t_output,
        pernr     LIKE pa0001-pernr,    "Personnel Number
        nachn     LIKE pa0002-nachn,    "Last name
        vorna     LIKE pa0002-vorna,    "First name
        gsber     LIKE pa0001-gsber,    "Business Area
        gtext     LIKE tgsbt-gtext,     "Business Area Text
        begda     LIKE pa0001-begda,    "Begin Date
        endda     LIKE pa0001-endda,    "End Date
        favor     LIKE pa0021-favor,    "Emergency Contact fName
        fanam     LIKE pa0021-fanam,    "Emergency Contact lName
        telnr     LIKE pa0106-telnr,    "Emergency Contact pNumber
       END OF t_output.

DATA:   alv_data    TYPE TABLE OF t_output WITH HEADER LINE,
        itab_output TYPE STANDARD TABLE OF t_output,
        wa_output   TYPE t_output.

**************************************************************************
*START ALV DATA                                                          *
**************************************************************************
TYPE-POOLS: slis.   "ALV

* Constants

CONSTANTS: gc_formname_top_of_page TYPE slis_formname VALUE 'TOP_OF_PAGE'.

DATA:  gt_fieldcat TYPE slis_t_fieldcat_alv,
       gs_variant  TYPE disvariant,
       alv_heading TYPE slis_t_listheader,
       gs_layout   TYPE slis_layout_alv,
       gs_print    TYPE slis_print_alv,
       gt_sort     TYPE slis_t_sortinfo_alv,
       gt_sp_group TYPE slis_t_sp_group_alv,
       gt_events   TYPE slis_t_event.

DATA: g_repid LIKE sy-repid VALUE sy-repid.
DATA: gt_list_top_of_page TYPE slis_t_listheader.

DATA:  g_boxnam     TYPE slis_fieldname VALUE  'box',
       p_f2code     LIKE sy-ucomm       VALUE  '&eta',
       p_lignam     TYPE slis_fieldname VALUE  'lights',
       g_save(1)    TYPE c,
       g_default(1) TYPE c,
       g_exit(1)    TYPE c,
       gx_variant   LIKE disvariant,
       g_variant    LIKE disvariant.

* ALV Grid Variants

DATA: alv_fieldcat     TYPE slis_t_fieldcat_alv,
      w_alv_fieldcat   TYPE LINE OF slis_t_fieldcat_alv,
      alv_events       TYPE slis_t_event,
      alv_layout       TYPE slis_layout_alv,
      alv_variant      TYPE disvariant,
      alv_grid_title   TYPE lvc_title,
      alv_report_title TYPE lvc_title.

DATA: reported_records_lines       TYPE i,
      reported_records_display(20) TYPE c.

DATA: grid_template LIKE disvariant,
      ret_tab       LIKE ddshretval OCCURS 0 WITH HEADER LINE.

DATA: tot_cnt           TYPE sy-tabix.
DATA: tot_lines         TYPE sy-tabix.
DATA: tot_cnt_c         TYPE c LENGTH 15.
DATA: tot_lines_c       TYPE c LENGTH 15.
DATA: v_selcnt          TYPE int4.                   " Number of EEs selected.
DATA: the_message(400)  TYPE c.

DATA: start_time      TYPE sy-uzeit.
DATA: end_time        TYPE sy-uzeit.
DATA: tot_time        TYPE sy-uzeit.
**************************************************************************
*END ALV DATA                                                            *
**************************************************************************
*----------------------------------------------------------------------*
*  SELECTION SCREEN - User Selection screen.
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK block1 WITH FRAME TITLE text-001.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 01(17) text-002.
SELECT-OPTIONS: s_pernr FOR pa0001-pernr.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 01(17) text-008.
SELECT-OPTIONS: s_gsber FOR pa0001-gsber.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 01(20) text-003.
PARAMETERS: k_date TYPE sy-datum DEFAULT sy-datum.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 01(20) text-007.
PARAMETERS: rec_amt TYPE i DEFAULT '5000'.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK block1.

SELECTION-SCREEN BEGIN OF BLOCK b_alv WITH FRAME TITLE text-004.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 01(20) text-005.
PARAMETERS: p_alv  TYPE disvariant-variant.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON (8) text-006 USER-COMMAND press.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN END OF BLOCK b_alv.
*----------------------------------------------------------------------*
*        INITIALIZATION                                                *
*----------------------------------------------------------------------*
INITIALIZATION.
*----------------------------------------------------------------------*
*  AT SELECTION-SCREEN ON VALUE-REQUEST                                *
*----------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_alv.
  PERFORM get_alv_variant CHANGING grid_template p_alv.
*----------------------------------------------------------------------*
*  AT SELECTION-SCREEN OUTPUT                                          *
*----------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
*----------------------------------------------------------------------*
*  AT SELECTION-SCREEN.                                                *
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  IF sy-ucomm = 'PRESS'.
    MESSAGE 'This report displays emergency contacts' TYPE 'I'.
  ENDIF.
*----------------------------------------------------------------------*
*  TOP-OF-PAGE.                                                        *
*----------------------------------------------------------------------*
TOP-OF-PAGE.
  CALL FUNCTION 'Z_WRITE_HEADER_FOOTER' "<-- This shows the Standard Header for Report Output
    EXPORTING
      type_head_foot   = 'H'
      not_confidential = 'X'
      title1           = 'Emergency Contact ALV Report'
      progtype         = 'R'.

*---------------------------------------------------------------------*
*        START-OF-SELECTION                                           *
*---------------------------------------------------------------------*
START-OF-SELECTION.

  GET TIME.
  start_time = sy-uzeit.

  IF NOT p_alv IS INITIAL.
    PERFORM check_alv_variant
    USING    p_alv
    CHANGING grid_template.
  ENDIF.

  PERFORM load_itab.             "Get data from all infotypes
  PERFORM get_emerg_record.      "Some logic to get emg. contact

  GET TIME.
  end_time = sy-uzeit.

  COMPUTE tot_time = end_time - start_time.

END-OF-SELECTION.
*---------------------------------------------------------------------*
* ALV Initialization Section                                          *
*---------------------------------------------------------------------*

* Initialize ALV Grid

  PERFORM   f_setup_alv_col_headings
  TABLES    itab_output
  CHANGING  alv_fieldcat.

  PERFORM   f_write_alv_report
  TABLES    itab_output.

  CLEAR: itab_output[].

*---------------------------------------------------------------------*
* Sub Routines Section - All FORM Definitions Goes here               *
*---------------------------------------------------------------------*

*---------------------------------------------------------------------*
*       Form  top_of_page
*---------------------------------------------------------------------*
*       This subroutine writes the list header to the top_of_page.
*---------------------------------------------------------------------*
FORM top_of_page.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = alv_heading.

ENDFORM.                    "top_of_page

*&---------------------------------------------------------------------*
*&      Form  load_itab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM load_itab.

  SELECT DISTINCT t1~pernr
                  t1~gsber
                  t1~begda
                  t1~endda
                  t2~nachn
                  t2~vorna
                  t3~favor
                  t3~fanam
                  t4~gtext
                  t5~telnr
        INTO CORRESPONDING FIELDS OF TABLE itab_input
        FROM  pa0001 AS t1
        JOIN  pa0002 AS t2
        ON    t1~pernr = t2~pernr
        JOIN  pa0021 AS t3
        ON    t2~pernr = t3~pernr
        JOIN  tgsbt  AS t4
        ON    t1~gsber = t4~gsber
        JOIN  pa0106 AS t5
        ON    t2~pernr = t5~pernr
        UP TO rec_amt ROWS
        WHERE t1~begda <= k_date AND
              t1~endda >= k_date AND
              t2~begda <= k_date AND
              t2~endda >= k_date AND
              t1~pernr IN s_pernr AND
              t1~gsber IN s_gsber
        ORDER BY t1~pernr t1~gsber t3~fanam.

ENDFORM.                    "load_itab

*&---------------------------------------------------------------------*
*&      Form  get_emerg_record
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_emerg_record.

  LOOP AT itab_input INTO wa_input.

    "Delete records that have a blank telephone number
    IF wa_input-telnr = ''.
      CLEAR wa_input.
    ENDIF.

    "Based upon the date, get the array data ready to display
    IF wa_input-begda <= sy-datum AND wa_input-endda >= sy-datum.
      wa_output-pernr = wa_input-pernr.
      wa_output-nachn = wa_input-nachn.
      wa_output-vorna = wa_input-vorna.
      wa_output-gsber = wa_input-gsber.
      wa_output-gtext = wa_input-gtext.
      wa_output-favor = wa_input-favor.
      wa_output-fanam = wa_input-fanam.
      wa_output-telnr = wa_input-telnr.
      wa_output-begda = wa_input-begda.
      wa_output-endda = wa_input-endda.
      COLLECT wa_output INTO itab_output.
    ENDIF.

    CLEAR wa_output.

  ENDLOOP.

ENDFORM.                    "get_emerg_record

*&---------------------------------------------------------------------*
*&      Form  col_titles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_FIELDNAME  text
*      -->P_STEXT      text
*      -->P_MTEXT      text
*      -->P_LTEXT      text
*      -->P_FIELDSIZE  text
*      -->P_SUBTOT     text
*      -->P_FREEZE     text
*      -->P_POS        text
*      -->P_FIELDCAT   text
*----------------------------------------------------------------------*
FORM col_titles  USING  p_fieldname
      p_stext
      p_mtext
      p_ltext
      p_fieldsize
      p_subtot
      p_freeze
CHANGING p_pos
  p_fieldcat TYPE slis_t_fieldcat_alv.

  DATA : wa_fieldcat LIKE LINE OF p_fieldcat.
  CLEAR: wa_fieldcat.

  wa_fieldcat-col_pos    =  p_pos.
  wa_fieldcat-fieldname  =  p_fieldname.
  wa_fieldcat-seltext_m  =  p_mtext.
  wa_fieldcat-seltext_l  =  p_ltext.
  wa_fieldcat-seltext_s  =  p_stext.
  wa_fieldcat-outputlen  =  p_fieldsize.

  IF p_freeze EQ 'X'.
    wa_fieldcat-key = 'X'.
    wa_fieldcat-fix_column = 'X'.
  ENDIF.

  IF p_freeze EQ 'N'.
    wa_fieldcat-no_out = 'X'.
  ENDIF.
*
*  IF p_subtot EQ 'X'.
*    wa_fieldcat-do_sum  =  'X'.
*    wa_fieldcat-no_zero =  'X'.
*    wa_fieldcat-just    =  'L'.
*  ENDIF.

  APPEND wa_fieldcat TO p_fieldcat.
  p_pos  = p_pos + 1.

ENDFORM.                    " headings

*&---------------------------------------------------------------------*
*&      Form  build_events
*&---------------------------------------------------------------------*
FORM build_events USING    p_events TYPE slis_t_event.

  DATA: ls_event TYPE slis_alv_event.
*
  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
    EXPORTING
      i_list_type = 0
    IMPORTING
      et_events   = p_events.

  READ TABLE p_events WITH KEY name =  slis_ev_top_of_page
  INTO ls_event.
  IF sy-subrc = 0.
    MOVE gc_formname_top_of_page TO ls_event-form.
    APPEND ls_event    TO p_events.
  ENDIF.

ENDFORM.                    " build_events

*&---------------------------------------------------------------------*
*&      Form  f_set_colors
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_set_colors.

  DATA: wa_cellcolor TYPE lvc_s_scol.
  DATA: ld_index TYPE sy-tabix.

*  LOOP AT itab_output INTO wa_output.
*    ld_index = sy-tabix.
*    IF wa_output-infoty = 'Infotype 0027'.
*      wa_cellcolor-fname = 'INFOTY'.
*      wa_cellcolor-color-col = '4'.
*      wa_cellcolor-color-int = '0'.
*      wa_cellcolor-COLOR-inv = '0'.
*      APPEND wa_cellcolor TO wa_output-CELLCOLOR.
*      MODIFY itab_output FROM wa_output INDEX ld_index TRANSPORTING CELLCOLOR.
*    ENDIF.
*  ENDLOOP.

ENDFORM.                    "f_set_colors

*&---------------------------------------------------------------------*
*&      Form  f_setup_alv_header
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->T_HEADING  text
*----------------------------------------------------------------------*
FORM f_setup_alv_header CHANGING t_heading TYPE slis_t_listheader.

  DATA: rpt_title TYPE c LENGTH 40.

  rpt_title = 'Emergency Contact Report'.

  PERFORM f_show_standard_header         TABLES t_heading USING rpt_title.
  PERFORM f_add_new_line_to_display      TABLES t_heading USING 'Key Date: '    k_date 'S'.
  PERFORM f_add_new_line_to_display      TABLES t_heading USING 'Start Time:'   start_time 'S'.
  PERFORM f_add_new_line_to_display      TABLES t_heading USING 'End Time:'     end_time 'S'.
  PERFORM f_add_new_line_to_display      TABLES t_heading USING 'Total Time Taken:' tot_time 'S'.
  PERFORM f_add_new_line_to_display      TABLES t_heading USING 'ALV Variant:' p_alv 'S'.
  PERFORM f_show_sel_option_entered      TABLES s_pernr t_heading USING 'PERNR' 'PERSNO'.
  PERFORM f_show_parameter_value_entered TABLES t_heading USING p_alv 'ALV:' 'SLIS_VARI' .

  DATA: v_cnt TYPE c LENGTH 9.
  DATA: v_tot TYPE i.

  DESCRIBE TABLE itab_output LINES v_tot.
  WRITE v_tot TO v_cnt.
  PERFORM f_add_new_line_to_display TABLES t_heading USING 'Total Records: ' v_cnt 'S'.

ENDFORM.                    "f_setup_alv_header

*&---------------------------------------------------------------------*
*&      Form  f_show_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->T_SHOW_OUTPUT        text
*      -->T_SHOW_ALV_FIELDCAT  text
*----------------------------------------------------------------------*
FORM f_show_alv TABLES t_show_output
                USING  t_show_alv_fieldcat TYPE slis_t_fieldcat_alv.


  alv_layout-colwidth_optimize = 'X'.
  alv_layout-zebra = 'X'.

*  alv_layout-coltab_fieldname = 'CELLCOLOR'.
*  alv_layout-info_fieldname = 'LINE_COLOR'.      "<-Needed for Line Color
*  alv_layout-coltab_fieldname = 'COLUMN_COLOR'.  "<-Needed to color individual cells

  CONCATENATE 'Generating ALV Report' '-Standby!' INTO the_message.
  PERFORM f_show_progress_message USING the_message v_selcnt v_selcnt.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      i_callback_top_of_page  = gc_formname_top_of_page
      i_callback_user_command = 'CALLBACK_LV'
      it_fieldcat             = t_show_alv_fieldcat[]
      it_sort                 = gt_sort[]
      it_events               = alv_events[]
      is_layout               = alv_layout
      is_variant              = grid_template
      i_save                  = 'A'
      i_grid_title            = alv_grid_title
    TABLES
      t_outtab                = t_show_output
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.

ENDFORM.                    "f_show_alv

*&---------------------------------------------------------------------*
*&      Form  f_show_progress_message
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->T_TEXT           text
*      -->COUNT_PROCESSED  text
*      -->INPUT_LINES      text
*----------------------------------------------------------------------*
FORM f_show_progress_message USING t_text count_processed input_lines.


  CALL FUNCTION 'PROGRESS_INDICATOR'
    EXPORTING
      i_text               = t_text
      i_processed          = count_processed
      i_total              = input_lines
      i_output_immediately = 'X'.

  COMMIT WORK.

ENDFORM.                    "f_show_progress_message

*&---------------------------------------------------------------------*
*&      Form  f_write_alv_report
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->T_OUTPUT   text
*----------------------------------------------------------------------*
FORM f_write_alv_report TABLES t_output.

  PERFORM f_set_colors.
  PERFORM f_setup_alv_header        CHANGING alv_heading.
  PERFORM f_show_alv                TABLES t_output
                                    USING  alv_fieldcat.


ENDFORM.                    "f_write_alv_report

*&---------------------------------------------------------------------*
*&      Form  f_setup_alv_col_headings
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->T_OUTPUT        text
*      -->T_ALV_FIELDCAT  text
*----------------------------------------------------------------------*
FORM f_setup_alv_col_headings TABLES t_output
                              CHANGING t_alv_fieldcat TYPE slis_t_fieldcat_alv.


* Im Lazy and so I dont like to define all the column headings myself
* I wanted to find a way to determine the headings from DDIC
* If I defined my internal table with each data element using LIKE reference,
* then I found a way to use the "LIKE" reference to get the DDIC heading
* values If I could not find a LIKE reference and had to use a TYPE reference,
* then I use the name of the Field itself in the ALV Heading

  TYPE-POOLS: abap.
  DATA: it_details  TYPE abap_compdescr_tab,
        wa_comp     TYPE abap_compdescr.
  DATA: ref_descr   TYPE REF TO cl_abap_structdescr.

  ref_descr ?= cl_abap_typedescr=>describe_by_data( t_output ).
  it_details[] = ref_descr->components[].
  "<-- it_details Contains a list of all FIELDS of the internal table

*Now Get the SText, LText, MText of DDIC Elements if used in the
*structure
  DATA: hlp(61).
  DATA: offset        LIKE dfies-offset.
  DATA: dfies_zwi     LIKE dfies.
  DATA: dtelinfo_wa   TYPE dtelinfo.
  DATA: tabname       LIKE dd03p-tabname,
        lfieldname    LIKE dfies-lfieldname.

  DATA: i             LIKE sy-index.
  DATA: n(4)          TYPE n.
  DATA: field_tab     TYPE STANDARD TABLE OF dfies.
  DATA: wa_field_tab  TYPE dfies.

  FIELD-SYMBOLS: <f>.

  DESCRIBE FIELD t_output HELP-ID hlp.

  DO.
    i = sy-index.
    ASSIGN COMPONENT i OF STRUCTURE t_output TO <f>.
    IF sy-subrc <> 0 . EXIT. ENDIF.
    DESCRIBE FIELD <f> HELP-ID hlp.
    SPLIT hlp AT '-' INTO tabname lfieldname.

    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING
        tabname        = tabname
        lfieldname     = lfieldname
        all_types      = 'X'
      IMPORTING
        dfies_wa       = dfies_zwi
      EXCEPTIONS
        not_found      = 1
        internal_error = 2
        OTHERS         = 3.

    CHECK sy-subrc = 0.

    DESCRIBE DISTANCE BETWEEN t_output AND <f>
    INTO dfies_zwi-offset IN BYTE MODE.

    CLEAR dfies_zwi-tabname.

    dfies_zwi-position = i.
    n = i.

    CONCATENATE 'F' n INTO dfies_zwi-fieldname.
    dfies_zwi-mask+2(1) = 'X'.         "Rollname für F1-Hilfe verantw.

*   Das Flag F4-Available muß jetzt aber aus dem DTEL kommen.
    CLEAR: dfies_zwi-f4availabl, dtelinfo_wa.
    CALL FUNCTION 'DDIF_NAMETAB_GET'
      EXPORTING
        tabname     = dfies_zwi-rollname
        all_types   = 'X'
      IMPORTING
        dtelinfo_wa = dtelinfo_wa
      EXCEPTIONS
        OTHERS      = 0.
    dfies_zwi-f4availabl = dtelinfo_wa-f4availabl.

*   RaviC: Make sure you populate the fieldname if result is blank
    IF dfies_zwi-lfieldname IS INITIAL.
      READ TABLE it_details INDEX i INTO wa_comp.
      MOVE wa_comp-name TO dfies_zwi-lfieldname.
    ENDIF.
    APPEND dfies_zwi TO field_tab.
    "<- FIELD_TAB will now contain all DDIC values
  ENDDO.

  DATA : wl_pos      TYPE i VALUE 1.

  LOOP AT it_details INTO wa_comp.

    CASE wa_comp-name. "<-- The columns Names must be in UPPER CASE
*     When you want to freeze a field use "X" before wl_pos
*     When you want to Hide a field Use "N" before wl_pos
      WHEN 'PERNR'.
        PERFORM col_titles USING wa_comp-name 'Persno' 'Personnel Num' 'Personnel Number' '4' '' ''                           wl_pos t_alv_fieldcat.
      WHEN 'CNAME'.
        PERFORM col_titles USING wa_comp-name 'FuNa' 'FullNam' 'Full Name' '4' '' 'N'                                         wl_pos t_alv_fieldcat.
      WHEN 'NACHN'.
        PERFORM col_titles USING wa_comp-name 'LName' 'LastName' 'LAST NAME' '4' '' 'N'                                       wl_pos t_alv_fieldcat.
      WHEN 'VORNA'.
        PERFORM col_titles USING wa_comp-name 'FName' 'FirstName' 'FIRST NAME' '4' '' 'N'                                     wl_pos t_alv_fieldcat.
      WHEN 'GSBER'.
        PERFORM col_titles USING wa_comp-name 'Biz. Area' 'Business Area' 'Business Area Code' '4' '' ''                      wl_pos t_alv_fieldcat.
      WHEN 'GSBER_T'.
        PERFORM col_titles USING wa_comp-name 'Biz. Area Txt' 'Biz. Area Text' 'Business Area Text' '100' '' ''               wl_pos t_alv_fieldcat.
      WHEN 'FAVOR'.
        PERFORM col_titles USING wa_comp-name 'EmFirstNam' 'Emerg First Name' 'Emergency First Name' '4' '' ''                wl_pos t_alv_fieldcat.
      WHEN 'FANAM'.
        PERFORM col_titles USING wa_comp-name 'EmLastNam' 'Emerg Last Name' 'Emergency Last Name' '4' '' ''                   wl_pos t_alv_fieldcat.
      WHEN 'TELNR'.
        PERFORM col_titles USING wa_comp-name 'TelNum' 'Telephone Num' 'Telephone Number' '4' '' ''                           wl_pos t_alv_fieldcat.
      WHEN 'WERKS'.
        PERFORM col_titles USING wa_comp-name 'Pers. Area' 'Personnel Area' 'Personnel Area Code' '4' '' ''                   wl_pos t_alv_fieldcat.
      WHEN 'WERKS_T'.
        PERFORM col_titles USING wa_comp-name 'Pers. Area Txt' 'Personnel Area Text' 'Personnel Area Text' '100' '' ''        wl_pos t_alv_fieldcat.
      WHEN 'BTRTL'.
        PERFORM col_titles USING wa_comp-name 'Pers. Subarea' 'Pers. Subarea Code' 'Personnel Subarea Code' '8' '' ''         wl_pos t_alv_fieldcat.
      WHEN 'BTRTL_T'.
        PERFORM col_titles USING wa_comp-name 'Pers. Subarea Txt' 'Pers. Subarea Title' 'Personnel Subarea Title' '60' '' ''  wl_pos t_alv_fieldcat.
      WHEN 'PLANS'.
        PERFORM col_titles USING wa_comp-name 'Pos. Obj ID' 'Position Object ID' 'Position Object ID' '8' '' 'X'              wl_pos t_alv_fieldcat.
      WHEN 'PLANS_D'.
        PERFORM col_titles USING wa_comp-name 'Pos. Abbr' 'Position Abbr' 'Position Abbr' '40' '' 'X'                         wl_pos t_alv_fieldcat.
      WHEN 'PLANS_T'.
        PERFORM col_titles USING wa_comp-name 'Pos. Title' 'Position Title' 'Position Title' '40' '' 'X'                      wl_pos t_alv_fieldcat.
      WHEN 'ORGEH'.
        PERFORM col_titles USING wa_comp-name 'Org Unit Object ID' 'Org Unit Object ID' 'Org Unit Object ID' '8' '' ''        wl_pos t_alv_fieldcat.
      WHEN 'ORGEH_D'.
        PERFORM col_titles USING wa_comp-name 'Org Unit Abbr' 'Org Unit Abbr' 'Org Unit Abbr' '40' '' ''                      wl_pos t_alv_fieldcat.
      WHEN 'ORGEH_T'.
        PERFORM col_titles USING wa_comp-name 'Org Unit Title' 'Org Unit Title' 'Org Unit Title' '60' '' ''                   wl_pos t_alv_fieldcat.
      WHEN 'STELL'.
        PERFORM col_titles USING wa_comp-name 'Job Object ID' 'Job Object ID' 'Job Object ID' '8' '' ''                       wl_pos t_alv_fieldcat.
      WHEN 'STELL_D'.
        PERFORM col_titles USING wa_comp-name 'Job Abbr' 'Job Abbr' 'Job Abbr' '40' '' ''                                     wl_pos t_alv_fieldcat.
      WHEN 'STELL_T'.
        PERFORM col_titles USING wa_comp-name 'Job Title' 'Job Title' 'Job Title' '60' '' ''                                  wl_pos t_alv_fieldcat.
      WHEN 'PERSG'.
        PERFORM col_titles USING wa_comp-name 'Employee Group' 'Employee Group' 'Employee Group' '60' '' 'N'                  wl_pos t_alv_fieldcat.
      WHEN 'PTEXT'.
        PERFORM col_titles USING wa_comp-name 'EE Group Title' 'EE Group Title' 'Employee Group Title' '60' '' ''             wl_pos t_alv_fieldcat.
      WHEN 'STATUS'.
        PERFORM col_titles USING wa_comp-name 'Active/Inactive UFI' 'Active/Inactive UFI' 'Active/Inactive UFI' '10' '' ''    wl_pos t_alv_fieldcat.
      WHEN 'EMRGN'.
        PERFORM col_titles USING wa_comp-name 'EmContact' 'Emerg. Contact' 'Emergency Contact Indicator' '10' '' ''           wl_pos t_alv_fieldcat.
      WHEN 'BEGDA'.
        PERFORM col_titles USING wa_comp-name 'Begin' 'Begin Date' 'Begin Date' '4' '' ''                                     wl_pos t_alv_fieldcat.
      WHEN 'ENDDA'.
        PERFORM col_titles USING wa_comp-name 'End' 'End Date' 'End Date' '4' '' ''                                           wl_pos t_alv_fieldcat.
      WHEN 'WRK_IND'.
        PERFORM col_titles USING wa_comp-name 'Work Force Indicator' 'Work Force Indicator' 'Work Force Indicator' '60' '' '' wl_pos t_alv_fieldcat.

      WHEN OTHERS.
        READ TABLE field_tab INTO wa_field_tab WITH KEY lfieldname = wa_comp-name.
        IF sy-subrc EQ 0. "<-- Entry Found in DDIC values
          PERFORM col_titles USING wa_comp-name
                wa_field_tab-scrtext_s
                wa_field_tab-scrtext_m
                wa_field_tab-scrtext_l
                wa_field_tab-outputlen '' ''
                wl_pos t_alv_fieldcat.

        ELSE. "<-- No Entry Found, Use the COLUMN Heading as the Variable Name itself

          PERFORM col_titles USING wa_comp-name wa_comp-name
                wa_comp-name wa_comp-name
                wa_comp-length '' ''
                wl_pos t_alv_fieldcat.

        ENDIF.
    ENDCASE.
  ENDLOOP.

ENDFORM.                    "f_setup_alv_col_headings

*&---------------------------------------------------------------------*
*&      Form  f_show_progress_message
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->T_TEXT           text
*      -->COUNT_PROCESSED  text
*      -->INPUT_LINES      text
*----------------------------------------------------------------------*
FORM f_show_progress_message_per USING t_text count_processed input_lines.

  DATA: current_line TYPE sy-tabix,
        total_lines  TYPE sy-tabix,
        show_message TYPE c LENGTH 1 VALUE 'N',
        percentage   TYPE p DECIMALS 2.

  MOVE count_processed TO current_line.
  MOVE input_lines     TO total_lines.

  IF current_line LT 3.
    show_message = 'Y'.
  ELSE.
    show_message = 'N'.
  ENDIF.

  percentage = current_line / total_lines * 100.

  CASE percentage.
    WHEN '25.00'.
      show_message = 'Y'.
    WHEN '50.00'.
      show_message = 'Y'.
    WHEN '75.00'.
      show_message = 'Y'.
    WHEN '100.00'.
      show_message = 'Y'.
  ENDCASE.

  IF total_lines = count_processed.
    show_message = 'Y'.
  ENDIF.

  IF show_message EQ 'Y'.

    CALL FUNCTION 'PROGRESS_INDICATOR'
      EXPORTING
        i_text               = t_text
        i_processed          = count_processed
        i_total              = input_lines
        i_output_immediately = 'X'.

    COMMIT WORK.

  ENDIF.

ENDFORM.                    "f_show_progress_message

*&--------------------------------------------------------------------*
*&      Form  callback_lv
*&--------------------------------------------------------------------*
FORM callback_lv USING r_ucomm LIKE sy-ucomm
                       rs_selfield TYPE slis_selfield.

  CASE r_ucomm.
    WHEN '&IC1'.
      PERFORM display_pa20 USING rs_selfield-tabindex.
  ENDCASE.

ENDFORM.                    "CALLBACK_LV

*&---------------------------------------------------------------------*
*&      Form  display_pa20
*&---------------------------------------------------------------------*
FORM display_pa20 USING p_index.

  READ TABLE alv_data  INDEX p_index.
  IF sy-subrc = 0.

    CALL FUNCTION 'HR_MASTERDATA_DIALOG'
      EXPORTING
        p_pernr          = alv_data-pernr
        p_infty          = ''
        p_activity       = 'DIS'    "<-- PA20 Mode
      EXCEPTIONS
        wrong_activity   = 1
        no_authorization = 2
        OTHERS           = 3.

    IF sy-subrc <> 0.
      "Raise Error if required
    ENDIF.
  ENDIF.


ENDFORM.                    "display_pa20
