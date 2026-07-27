# BizActor / Stored-Procedure Definitions — Phase 3

> Source-code analysis of the ASPX / code-behind screens (assignee: **Hughie**).
> Every BizActor / SP name below is extracted from the actual server calls in the source code.

## How BizActors are invoked

Each screen calls server-side **BizActors** (stored-procedure-like rules). Two invocation paths appear in the code:

| Call path | Source pattern | Typical use |
|---|---|---|
| **`sp_name`** (AJAX) | `../common/xml/CallBizJson.aspx?sp_name=<NAME>` | combobox loads, direct lookups |
| **`bizID`** (grid / tx) | `param.bizID = "<NAME>"`, `GetBizJsonByDictionary` | grid data binding, save / send transactions |
| **`bizID`** (grid data-options) | `data-options='{"bizID":"<SUFFIX>"}'` | grid-embedded id (see 0257 DataLake) |

The `sp_name` value **is** the BizActor / SP name; `bizID` is the same identifier passed to the transaction dictionary. Prefixes: **BR**=Business Rule, **DA**=Data Access, **COR/COM**=Common, **CUS**=Custom.

---

## Screen summary

| Screen ID | Page (EN) | # BizActors |
|---|---|---|
| GMES_IMES_0257 | DataLake indicators | 10 |
| GMES_IMES_0279 | Daily-record dashboard | 9 |
| GMES_IMES_0312 | Rework result inquiry (admin) | 9 |
| GMES_IMES_0530 | ERP I/F result [production] | 12 |
| GMES_IMES_0531 | ERP I/F result [prev period] | 3 |
| GMES_IMES_0560 | Stock management status | 7 |
| GMES_IMES_0560_01 | Abnormal rack input | 8 |
| GMES_IMES_0560_02 | Abnormal collection confirm | 5 |
| GMES_IMES_0560_03 | Abnormal collection common code | 3 |
| GMES_IMES_0560_04 | Abnormal rack | 3 |
| GMES_IMES_0560_05 | Abnormal LOT calc | 2 |
| GMES_IMES_0560_06 | Abnormal product LOT note | 2 |
| GMES_IMS_0581 | ERP input adjustment | 11 |
| GMES_IMS_0585 | ERP point-in-time inventory I/F history | 5 |
| GMES_IMS_0924 | Cycle-count entry | 6 |
| GMES_IMS_0926 | Send cycle-count variance to ERP | 7 |
| GMES_IMS_0927 | ERP free-supply retro adjustment | 3 |
| **Total** | **17 screens** | **105** |

> Note: `Tables` are intentionally omitted — table names live inside the server-side BizActor / stored-procedure body, which is not part of this ASPX source folder and cannot be verified from it.

---

## GMES_IMES_0257 — DataLake indicators
*Chỉ số DataLake*

**10 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_IM_SEL_AREA_CBO` | bizID (combo) | BR | Query area combobox list |
| 2 | `BR_IM_SEL_PRODUCTGROUP_BY_AREA_CBO` | bizID (combo) | BR | Query product group By area combobox list |
| 3 | `BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO` | bizID (combo) | BR | Query equipment segment By process-group combobox list |
| 4 | `DA_SEL_FN_DL_GOODRATE` | bizID (grid, base `DA_SEL_FN_DL_`) | DA | Query function DataLake good-rate |
| 5 | `DA_SEL_FN_DL_LOSSRATE` | bizID (grid, base `DA_SEL_FN_DL_`) | DA | Query function DataLake loss-rate |
| 6 | `DA_SEL_FN_DL_YIELD_RTY_SHOP` | bizID (grid, base `DA_SEL_FN_DL_`) | DA | Query function DataLake yield RTY shop |
| 7 | `DA_SEL_FN_DL_BURNING` | bizID (grid, base `DA_SEL_FN_DL_`) | DA | Query function DataLake burning |
| 8 | `DA_SEL_FN_DL_SUBDIVISION` | bizID (grid, base `DA_SEL_FN_DL_`) | DA | Query function DataLake subdivision |
| 9 | `DA_SEL_FN_DL_PACKHISTORY` | bizID (grid, base `DA_SEL_FN_DL_`) | DA | Query function DataLake packing history |
| 10 | `DA_SEL_FN_DL_REWORKHISTORY` | bizID (grid, base `DA_SEL_FN_DL_`) | DA | Query function DataLake rework history |

## GMES_IMES_0279 — Daily-record dashboard
*Bảng tình trạng nhật ký*

**9 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_IM_SEL_AREA_CBO` | sp_name (AJAX) | BR | Query area combobox list |
| 2 | `BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO` | sp_name (AJAX) | BR | Query equipment segment By process-group combobox list |
| 3 | `COR_SEL_EQUIPMENTSEGMENT_BY_AREAID` | sp_name (AJAX) | COR | Query equipment segment By area |
| 4 | `DA_IM_BAS_SEL_DAILYRECORD_TYPE` | sp_name (AJAX) | DA | Query daily record Type |
| 5 | `BR_IM_PRD_SEL_DYRD_DASHBOARD` | bizID (grid/tx) | BR | Query production daily record dashboard |
| 6 | `COM_SEL_MenuInfo` | bizID (grid/tx) | COM | Query MenuInfo |
| 7 | `DA_IM_BAS_SEL_DAILYRECORD_TEMPLATE` | bizID (grid/tx) | DA | Query daily record template |
| 8 | `DA_IM_PRD_SEL_DYRD_COMMON` | bizID (grid/tx) | DA | Query production daily record common |
| 9 | `DA_IM_BAS_SEL_DAILYRECORD_MONTH_DAY_WEEK` | bizID (grid/tx) | DA | Query daily record month Day Week |

## GMES_IMES_0312 — Rework result inquiry (admin)
*Tra cứu thành tích tái xử lý [Quản trị]*

**9 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `DA_PRD_SEL_COMMONCODE_REPROC_SUM` | sp_name (AJAX) | DA | Query production common code reprocess Sum |
| 2 | `BR_IM_SEL_AREA_CBO` | sp_name (AJAX) | BR | Query area combobox list |
| 3 | `BR_IM_SEL_PRODUCTGROUP_BY_AREA_CBO` | sp_name (AJAX) | BR | Query product group By area combobox list |
| 4 | `BR_IM_SEL_PROCESS_BY_PCSGID_CBO` | sp_name (AJAX) | BR | Query process By process-seg combobox list |
| 5 | `BR_IM_SEL_PROCESSSEGMENT_BY_PCSGID_CBO` | sp_name (AJAX) | BR | Query process segment By process-seg combobox list |
| 6 | `BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO` | sp_name (AJAX) | BR | Query equipment segment By process-group combobox list |
| 7 | `BR_IM_SEL_EQUIPMENT_SHOP_CBO` | sp_name (AJAX) | BR | Query equipment shop combobox list |
| 8 | `DA_PRD_SEL_WIP_CLOSE_MONTH_OR_DATE` | bizID (grid/tx) | DA | Query production WIP closing month Or Date |
| 9 | `DA_PRD_SEL_MLOT_BY_EQPT_REPROC_SUM_NEW` | bizID (grid/tx) | DA | Query production material LOT By equipment reprocess Sum new |

## GMES_IMES_0530 — ERP I/F result [production]
*Kết quả I/F ERP [Thành tích]*

**12 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_COM_GET_EQUIPMENT_CBO` | sp_name (AJAX) | BR | Get equipment combobox list |
| 2 | `DA_PRD_SEL_EQSGID_PROD_RST` | sp_name (AJAX) | DA | Query production equipment-seg production result result |
| 3 | `BR_COM_GET_PRODUCTGROUP_AREA_CBO` | sp_name (AJAX) | BR | Get product group area combobox list |
| 4 | `DA_BAS_SEL_AREA_CBO` | sp_name (AJAX) | DA | Query area combobox list |
| 5 | `BR_COM_GET_COMMONCODE_CBO` | sp_name (AJAX) | BR | Get common code combobox list |
| 6 | `DA_PRD_SEL_ERP_IF_PROD` | bizID (grid/tx) | DA | Query production ERP I/F production result |
| 7 | `DA_IM_PRD_SEL_ERP_IF_MATERIAL_INPUT` | bizID (grid/tx) | DA | Query production ERP I/F material input |
| 8 | `DA_PRD_SEL_ERP_IF_MATERIAL_INPUT` | bizID (grid/tx) | DA | Query production ERP I/F material input |
| 9 | `BR_INF_REG_ERP_PRODRESULT_BUDAT` | bizID (grid/tx) | BR | Register/Insert interface ERP production result posting date |
| 10 | `DA_BAS_SEL_TB_SFC_WIPCLOSEMONTH` | bizID (grid/tx) | DA | Query table shop-floor WIP-close month |
| 11 | `DA_PRD_UPD_ERP_IF_PROD_TRANSFLAG` | bizID (grid/tx) | DA | Update production ERP I/F production result transfer flag |
| 12 | `DA_PRD_UPD_ERP_IF_MATERIAL_INPUT_TRANSFLAG` | bizID (grid/tx) | DA | Update production ERP I/F material input transfer flag |

## GMES_IMES_0531 — ERP I/F result [prev period]
*Kết quả I/F ERP [Kỳ trước]*

**3 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_COM_GET_COMMONCODE_CBO` | sp_name (AJAX) | BR | Get common code combobox list |
| 2 | `DA_PRD_SEL_ERP_IF_WIPCLOSE` | bizID (grid/tx) | DA | Query production ERP I/F WIP close |
| 3 | `DA_PRD_SEL_ERP_IF_MOVESTOCK` | bizID (grid/tx) | DA | Query production ERP I/F stock move |

## GMES_IMES_0560 — Stock management status
*Tình trạng quản lý tồn kho*

**7 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_IM_SEL_CommonCode` | sp_name + bizID | BR | Query common code |
| 2 | `BR_IM_SEL_AREA_CBO` | bizID (grid/tx) | BR | Query area combobox list |
| 3 | `DA_IM_COM_SEL_WAREHOUSE_CBO` | bizID (grid/tx) | DA | Query warehouse combobox list |
| 4 | `BR_IM_COM_GET_PROD_CLCTITEM` | bizID (grid/tx) | BR | Get production result collection item |
| 5 | `BR_IM_STK_GET_RACK_ABNORMAL` | bizID (grid/tx) | BR | Get stock rack abnormal |
| 6 | `BR_IM_PRD_SEL_LOT_ABNORMAL_INSPRESULT` | bizID (grid/tx) | BR | Query production LOT abnormal inspection result |
| 7 | `BR_IM_BAS_REG_ABNORMAL_PROD_LOTNOTE` | bizID (grid/tx) | BR | Register/Insert abnormal production result LOT note |

## GMES_IMES_0560_01 — Abnormal rack input
*[Popup] Nhập kho/thùng bất thường*

**8 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_IM_SEL_AREA_CBO` | bizID (grid/tx) | BR | Query area combobox list |
| 2 | `BR_IM_SEL_PRODUCTGROUP_BY_AREA_CBO` | bizID (grid/tx) | BR | Query product group By area combobox list |
| 3 | `BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO` | bizID (grid/tx) | BR | Query equipment segment By process-group combobox list |
| 4 | `DA_IM_BAS_SEL_PCSGID_BY_EQSGID` | bizID (grid/tx) | DA | Query process-seg By equipment-seg |
| 5 | `BR_IM_SEL_PROCESS_BY_PCSGID_CBO` | bizID (grid/tx) | BR | Query process By process-seg combobox list |
| 6 | `DA_IM_BAS_SEL_EQPT_HOPPER` | bizID (grid/tx) | DA | Query equipment hopper |
| 7 | `DA_IM_BAS_SEL_EQUIPMENTATTR_TBL` | bizID (grid/tx) | DA | Query equipment attribute table |
| 8 | `BR_IM_STK_GET_RACK_ABNORMAL` | bizID (grid/tx) | BR | Get stock rack abnormal |

## GMES_IMES_0560_02 — Abnormal collection confirm
*[Popup] Xác nhận hạng mục thu thập bất thường*

**5 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_IM_COM_GET_PROD_CLCTITEM` | bizID (grid/tx) | BR | Get production result collection item |
| 2 | `BR_IM_GET_PROD_PRODUCTPROCESSQUALSPEC` | bizID (grid/tx) | BR | Get production result product-process quality spec |
| 3 | `BR_IM_COM_GET_PROD_CLCTITEM_SPEC` | bizID (grid/tx) | BR | Get production result collection item spec |
| 4 | `BR_IM_REG_ABNORMAL_CLCTITEM_COMMONCODE` | bizID (grid/tx) | BR | Register/Insert abnormal collection item common code |
| 5 | `DA_IM_STK_SEL_RACK_ABNORMAL_CONFIRM` | bizID (grid/tx) | DA | Query stock rack abnormal confirm |

## GMES_IMES_0560_03 — Abnormal collection common code
*[Popup] Mã chung hạng mục thu thập bất thường*

**3 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_IM_SEL_CommonCode` | sp_name (AJAX) | BR | Query common code |
| 2 | `BR_IM_COM_GET_PROD_CLCTITEM` | bizID (grid/tx) | BR | Get production result collection item |
| 3 | `BR_IM_REG_ABNORMAL_CLCTITEM_COMMONCODE` | bizID (grid/tx) | BR | Register/Insert abnormal collection item common code |

## GMES_IMES_0560_04 — Abnormal rack
*[Popup] Rack bất thường*

**3 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_IM_STK_GET_RACK_ABNORMAL` | bizID (grid/tx) | BR | Get stock rack abnormal |
| 2 | `DA_IM_SEL_AREA_CBO` | bizID (grid/tx) | DA | Query area combobox list |
| 3 | `BR_IM_SEL_CommonCode` | bizID (grid/tx) | BR | Query common code |

## GMES_IMES_0560_05 — Abnormal LOT calc
*[Popup] Tính toán LOT bất thường*

**2 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `DA_IM_BAS_SEL_PROD_CLCTITEM` | sp_name (AJAX) | DA | Query production result collection item |
| 2 | `BR_IM_PRD_SEL_LOT_ABNORMAL_CALC` | bizID (grid/tx) | BR | Query production LOT abnormal calculation |

## GMES_IMES_0560_06 — Abnormal product LOT note
*[Popup] Ghi chú LOT sản phẩm bất thường*

**2 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `DA_IM_STK_SEL_RACK_ABNORMAL_CONFIRM` | bizID (grid/tx) | DA | Query stock rack abnormal confirm |
| 2 | `BR_IM_BAS_REG_ABNORMAL_PROD_LOTNOTE` | bizID (grid/tx) | BR | Register/Insert abnormal production result LOT note |

## GMES_IMS_0581 — ERP input adjustment
*Điều chỉnh nhập liệu ERP*

**11 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_COM_GET_STOCKLOCATION_AREAID_CBO` | sp_name (AJAX) | BR | Get stock location area combobox list |
| 2 | `CUS_SEL_STORAGELOCATION_CBO` | sp_name (AJAX) | CUS | Query storage location combobox list |
| 3 | `COM_SEL_CommonCode` | sp_name (AJAX) | COM | Query common code |
| 4 | `BR_COM_GET_MULTI_CLOSING_CBO` | bizID (grid/tx) | BR | Get multi closing combobox list |
| 5 | `DA_PRD_SEL_ERP_INPUT_ADJUST` | bizID (grid/tx) | DA | Query production ERP input adjustment |
| 6 | `DA_PRD_GET_WORKORDER_INFO_COMMON_2` | bizID (grid/tx) | DA | Get production work order info common 2 |
| 7 | `DA_PRD_SEL_MATERIALINFO` | bizID (grid/tx) | DA | Query production material info |
| 8 | `BR_PRD_ERP_SEND_INPUT_ADJUST` | bizID (grid/tx) | BR | Send to ERP production ERP input adjustment |
| 9 | `BR_PRD_CHK_INPUT_ADJUST` | bizID (grid/tx) | BR | Validate production input adjustment |
| 10 | `BR_PRD_REG_START_MOVE_WIP_V2` | bizID (grid/tx) | BR | Register/Insert production start Move WIP v2 |
| 11 | `BR_PRD_REG_START_MOVE_WIP_CLOSING` | bizID (grid/tx) | BR | Register/Insert production start Move WIP closing |

## GMES_IMS_0585 — ERP point-in-time inventory I/F history
*Tra cứu lịch sử I/F tồn kho theo thời điểm ERP*

**5 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `BR_COM_GET_COMMONCODE_CBO` | sp_name (AJAX) | BR | Get common code combobox list |
| 2 | `CUS_SEL_STORAGELOCATION_RANGE_CBO` | sp_name (AJAX) | CUS | Query storage location range combobox list |
| 3 | `DA_PRD_SEL_ERP_IF_HISTORY_TOTAL` | bizID (grid/tx) | DA | Query production ERP I/F history total |
| 4 | `DA_PRD_SEL_ERP_IF_HISTORY_TOTAL_COUNT` | bizID (grid/tx) | DA | Query production ERP I/F history total count |
| 5 | `DA_PRD_SEL_ERP_IF_HISTORY` | bizID (grid/tx) | DA | Query production ERP I/F history |

## GMES_IMS_0924 — Cycle-count entry
*Nhập kiểm kê tồn kho*

**6 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `CUS_SEL_STOCKLOCATION_AREAID_CBO` | sp_name (AJAX) | CUS | Query stock location area combobox list |
| 2 | `CUS_SEL_STORAGELOCATION_RANGE_CBO` | sp_name (AJAX) | CUS | Query storage location range combobox list |
| 3 | `BR_PRD_GET_INV_STOCK_MNTH` | bizID (grid/tx) | BR | Get production inventory stock month |
| 4 | `BR_PRD_UPD_CLOSE_RSLT` | bizID (grid/tx) | BR | Update production closing result |
| 5 | `DA_PRD_SEL_CHK_CLOSE_STAT` | bizID (grid/tx) | DA | Query production Chk closing status |
| 6 | `COR_SEL_MATERIAL_TBL` | bizID (grid/tx) | COR | Query material table |

## GMES_IMS_0926 — Send cycle-count variance to ERP
*Phản ánh kiểm kê vào ERP*

**7 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `CUS_SEL_STOCKLOCATION_AREAID_CBO` | sp_name (AJAX) | CUS | Query stock location area combobox list |
| 2 | `CUS_SEL_STORAGELOCATION_RANGE_CBO` | sp_name (AJAX) | CUS | Query storage location range combobox list |
| 3 | `DA_PRD_SEL_ERP_STOCK_GAP_DISB` | bizID (grid/tx) | DA | Query production ERP stock gap disbursement |
| 4 | `BR_PRD_SND_DISB_DIFF_PP0547_SO` | bizID (grid/tx) | BR | Send to ERP production disbursement difference (PP0547) send-out |
| 5 | `BR_PRD_UPD_DISB_SENDFLAG` | bizID (grid/tx) | BR | Update production disbursement send flag |
| 6 | `BR_PRD_RETURN_RSLT_PP0547` | bizID (grid/tx) | BR | Return production result (PP0547) |
| 7 | `DA_PRD_SEL_CHK_SEND_STAT` | bizID (grid/tx) | DA | Query production Chk Send status |

## GMES_IMS_0927 — ERP free-supply retro adjustment
*Điều chỉnh hồi tố cấp phát miễn phí ERP*

**3 BizActor(s)**

| # | BizActor / SP Name | Call path | Prefix | Purpose |
|---|---|---|---|---|
| 1 | `DA_PRD_SEL_ERP_POST_RESULT` | bizID (grid/tx) | DA | Query production ERP posting result |
| 2 | `DA_PRD_SEL_ERP_POST_RESULT_DETAIL` | bizID (grid/tx) | DA | Query production ERP posting result detail |
| 3 | `BR_PRD_SND_SUPPLY_ADJUST_MM0476_SO` | bizID (grid/tx) | BR | Send to ERP production supply adjustment (MM0476) send-out |
