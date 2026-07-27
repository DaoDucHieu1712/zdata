# bizActor Definition — GMES_IMES_0239 / GMES_IMES_0240 / GMES_IMES_2612

All bizIDs used by the three screens (including the `0240_1` popup), extracted from the `.aspx` / `.aspx.cs` sources in this folder.

Three calling styles appear in the code:

| Style | How the bizID is passed | Endpoint |
|---|---|---|
| `param.bizID = "..."` + `sendRequestMethod` / `sendRequest` / `UCRealgrid.CallRequest` | POST body with `inTableNames` / `outTableNames` | page WebMethod (`GetData`, `GetDataSet`, `GetDataList`, `ExecuteData`) or `/GMES_COM/Service/CallBizJson.aspx/GetBizJsonByDictionary` |
| `sp_name=...` in a combobox `url:` | query string | `../common/xml/CallBizJson.aspx` |
| `CallBizAjax({ SP_NAME: "..." })` | JSON body key `SP_NAME` | common ajax helper (used in 0240 only) |

Legend — **Type**: `BR_` Business Rule, `DA_` Data Access, `COR_` core. **R/X**: R = read/select, X = execute (insert/update/delete).

---

## 1. GMES_IMES_0239 — Equipment daily inspection (LMS) info

### 1.1 Transaction / grid bizIDs (`GMES_IMES_0239.aspx`)

| # | bizID | Called from | Line | Endpoint (WebMethod) | inTableNames | outTableNames | R/X | Purpose |
|---|---|---|---|---|---|---|---|---|
| 1 | `DA_IM_SEL_PERSON_BY_EQPT` | `ucMasterRealgrid_gridView.onCellEdited` (inside `InitRealgrid`) | 629 | `CallBizJson.aspx/GetBizJsonByDictionary` | (dictionary) | (dictionary) | R | Resolve worker(s) assigned to the equipment when the 작업자 cell is edited |
| 2 | `BR_IM_PRD_REG_EQUIPMENTNOTE` | `OnChangeData(eqptId, calDate, shift, note)` | 731 | `GMES_IMES_0239.aspx/ExecuteData` | `INDATA` | – | X | Save worker / production note (작업자·생산비고) |
| 3 | `BR_IM_LMS_GET_EQPT_INSP_DAILY_INFO` | `GetData()` | 785 | `GMES_IMES_0239.aspx/GetDataList` | `INDATA` | `OUTDATA_COL,OUTDATA_INFO,OUTDATA_NOTE` | R | Main search — daily equipment-inspection data |
| 4 | `BR_IM_SEL_EQUIPMENT_SHOP_CBO` | `GetData()` via `param.eqptBizId` | 789 | same call as #3 — executed **server-side** inside `GetDataList` | (items reused) | `RSLTDT` | R | Second biz called by the WebMethod to fetch `EQPTNAME_S` and stamp it onto every result row |

⚠ #4 is unusual: `GMES_IMES_0239.aspx.cs:76` `GetDataList(..., string eqptBizId)` runs **two** bizActor calls, then pivots `OUTDATA_COL` rows into dynamic `COL_xxx` / `COL_xxx_COLOR` columns and left-joins `OUTDATA_NOTE`. The grid schema is therefore built at runtime from the biz result, not declared in the aspx.

### 1.2 Combobox bizIDs (`sp_name=`)

| bizID (sp_name) | Called from | Line | Purpose |
|---|---|---|---|
| `BR_IM_SEL_AREA_CBO` | `SetArea()` | 208 | Plant / building (공장·동) |
| `BR_IM_SEL_PRODUCTGROUP_BY_AREA_CBO` | `SetPdgr(areaRow)` | 265 | Product group |
| `BR_IM_SEL_PROCESS_BY_PCSGID_CBO` | `SetProc()` | 294 | Unit process |
| `BR_IM_SEL_PROCESSSEGMENT_BY_PCSGID_CBO` | `SetPcsg()` | 321 | Process segment |
| `BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO` | `SetEqsg()` | 347 | Line / room |
| `BR_IM_SEL_EQUIPMENT_SHOP_CBO` | `SetEqpt()` | 409 | Equipment |

---

## 2. GMES_IMES_0240 — Measurement data management (측정정보관리)

### 2.1 Transaction / grid bizIDs (`GMES_IMES_0240.aspx`)

| # | bizID | Called from | Line | Endpoint (WebMethod) | inTableNames | outTableNames | R/X | Purpose |
|---|---|---|---|---|---|---|---|---|
| 1 | `DA_IM_PRD_SEL_WIPCLOSE` | `setCloseMonth()` | 93 | `CallBizJson.aspx/GetBizJsonByDictionary` | (dictionary) | (dictionary) | R | Read the WIP close month to bound the editable date range |
| 2 | `DA_IM_SEL_PC_LIST` | `changePC(itemIndex, MTRLID)` | 1242 | `GMES_IMES_0240.aspx/GetData` | `RQSTDT` | `RSLTDT` | R | PC (자재) list for the PC-type dropdown cell |
| 3 | `DA_IM_BAS_SEL_EQUIPMENTSEGMENT_TBL` | `changeEQSG(itemIndex, EQSGID)` | 1268 | `GMES_IMES_0240.aspx/GetData` | `RQSTDT` | `RSLTDT` | R | Equipment-segment lookup for the EQSG dropdown cell |
| 4 | `BR_IM_LMS_SEL_RTY_INFO` | `searchData()` | 1362 | `GMES_IMES_0240.aspx/GetData` | `INDATA` | `OUTDATA` | R | Main search — measurement data grid |
| 5 | `BR_IM_LMS_REG_MEASURE_DATA` | `chkDeleteProc(...)` (delete path) | 1498 | `GMES_IMES_0240.aspx/ExecuteData` | `INDATA` | – | X | Delete measurement rows (`MES_FLAG='N'`, `SEQ=200`). Renamed from `DA_IM_LMS_UPD_MEASURE_DATA` on 2021-10-19 |
| 6 | `BR_IM_PRD_REG_MEASREMENT` | `SaveData()` | 1739 | `GMES_IMES_0240.aspx/ExecuteData` | `INDATA` | – | X | Save/register measurement data (branching per measure item type) |

### 2.2 Combobox bizIDs (`sp_name=`)

| bizID (sp_name) | Called from | Line | Purpose |
|---|---|---|---|
| `BR_IM_SEL_AREA_CBO` | `SetArea()` | 180 | Plant / building |
| `BR_IM_SEL_PRODUCTGROUP_BY_AREA_CBO` | `SetGrade(record)` | 235 | Product group |
| `BR_IM_SEL_PROCESS_BY_PCSGID_CBO` | `SetProcess()` | 258 | Unit process |
| `BR_IM_SEL_PROCESSSEGMENT_BY_PCSGID_CBO` | `SetProcessSegment()` | 283 | Process segment |
| `BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO_FOR_MEASURE` | `SetLine(areaId, PDGRID)` | 305 | Line combo, measurement-specific variant |
| `BR_CUS_SEL_COMMONCODE_CBO_CMCODE` (`CMCDTYPE=MeasureItem`, `CMCODE='CA','EE','MS','OA','PC','PQ','SD'`) | `SetMeasureItem()` | 359 | Measurement item combo — **drives the whole grid layout** |
| `BR_CUS_SEL_COMMONCODE_CBO_CMCODE` (`CMCDTYPE=UNIT`, `CMCODE='Kg','NM3'`) | `setUnit()` | 428 | Unit combo |

### 2.3 `CallBizAjax` bizIDs (in-cell dropdown data sets)

| bizID (SP_NAME) | Called from | Line | Fills |
|---|---|---|---|
| `BR_IM_SEL_EQUIPMENT_SHOP_CBO` (`S29='DIVISION'`) | `SetEquipmentItem(areaid, eqsgid)` | 405 | `EquipLabel` / `EquipValue` |
| `BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO_FOR_MEASURE` | `ChangeItemGrid()` | 506 | `EqsgLabel` / `EqsgValue` |
| `BR_IM_COM_GET_COMMONCODE_CBO` (`CMCDTYPE=Measure_EE`) | `ChangeItemGrid()` | 520 | `EeLabel` / `EeValue` |
| `BR_IM_COM_GET_COMMONCODE_CBO` (`CMCDTYPE=OXY_GEN_KIND`) | `ChangeItemGrid()` | 531 | `OaLabel` / `OaValue` |
| `BR_CUS_SEL_COMMONCODE_CBO_CMCODE` (`CMCDTYPE=UNIT`) | `ChangeItemGrid()` | 543 | `UnitLabel` / `UnitValue` |
| `DA_IM_SEL_PC_LIST` | `ChangeItemGrid()` | 558 | `PcLabel` / `PcValue` |
| `BR_IM_COM_GET_COMMONCODE_CBO` (`CMCDTYPE=PC_GEN_KIND`) | `ChangeItemGrid()` | 570 | `PcLabel_IK` / `PcValue_IK` |
| `BR_IM_COM_GET_COMMONCODE_CBO` (`CMCDTYPE=Measure_PQ`) | `ChangeItemGrid()` | 583 | `PQLabel` / `PQValue` |
| `BR_CUS_SEL_COMMONCODE_CBO_CMCODE` (`CMCDTYPE=UNIT`) | `InitGrid(code)` | 607 | Unit dropdown inside the grid |

Commented out: `BR_IM_SEL_AREA_CBO` (line 492), `BR_IM_COM_GET_COMMONCODE_CBO` combo URLs (lines 358, 427).

### 2.4 Popup — `GMES_IMES_0240_1.aspx` (Excel upload)

| # | bizID | Called from | Line | Endpoint | inTableNames | outTableNames | R/X | Purpose |
|---|---|---|---|---|---|---|---|---|
| 1 | `BR_CUS_SEL_COMMONCODE_CBO_CMCODE` (`CMCDTYPE=MeasureItem`) | `SetMeasureItem()` | 232 | `CallBizJson.aspx` (combo) | – | – | R | Measurement item combo |
| 2 | `BR_IM_PRD_REG_MEASREMENT` | `SaveData()` — branch A | 534 | `GMES_IMES_0240_1.aspx/ExecuteData` | `INDATA` | – | X | Save uploaded measurement rows |
| 3 | `BR_IM_PRD_REG_MEASREMENT` | `SaveData()` — branch B | 591 | `GMES_IMES_0240_1.aspx/ExecuteData` | `INDATA` | – | X | Same biz, alternate item-type branch |
| 4 | `BR_IM_PRD_CHK_EXCELDATA` | `getCHK_YN()` — branch A | 687 | `GMES_IMES_0240_1.aspx/GetData` | `INDATA` | `OUTDATA` | R | Validate uploaded Excel rows before save |
| 5 | `BR_IM_PRD_CHK_EXCELDATA` | `getCHK_YN()` — branch B | 775 | `GMES_IMES_0240_1.aspx/GetData` | `INDATA, ` ⚠ | `OUTDATA` | R | Same validation, alternate branch |

⚠ Line 777 has `param.inTableNames = 'INDATA, '` — a trailing comma/space, which produces an empty second table name.

---

## 3. GMES_IMES_2612 — WIP close & ERP posting (재공마감 · ERP 전송)

### 3.1 Save / close bizIDs

| # | bizID | Called from | Line | Endpoint (WebMethod) | inTableNames | outTableNames | R/X | Purpose |
|---|---|---|---|---|---|---|---|---|
| 1 | `BR_IM_PRD_UPD_WIPCLOSE_PACK` | `SavePackWipClose(pStatus)` | 337 | `2612/ExecuteData` | `RQSTDT` | – | X | Update packing WIP-close status |
| 2 | `BR_IM_PRD_REG_LOT_PROD_LOTMATERIALHISTORY` | `SaveProdData(WORKTYPE)` | 747 | `2612/ExecuteData` | `INDATA0,INDATA` | – | X | Register LOT production / material history |
| 3 | `BR_IM_UPD_WORKORDER_CLOSE` | `ConfirmSend(STATUS)` | 823 | `2612/ExecuteData` | `INDATA_INIT,INDATA` | – | X | Close the work order (확정) |
| 4 | `BR_IM_PRD_UPD_WIPCLOSE` | `SaveWorkOrderData(WORKTYPE)` | 933 | `2612/ExecuteData` | `INDATA,WIPCLOSE_OT_LIST,WIPCLOSE_IN_LIST` | – | X | Update WIP close with in/out lists |

### 3.2 ERP send bizIDs

| # | bizID | Called from | Line | Endpoint | inTableNames | outTableNames | R/X | Purpose |
|---|---|---|---|---|---|---|---|---|
| 5 | `BR_IM_REG_WORKORDER_CLOSE_ERP_SND` | `ErpSend(SECTION)` | 1174 | `2612/GetDataSet` | `INDATA_INIT,INDATA` | `IN_INMTRL,OT_INMTRL,INMOVE` | R→X | Build the ERP payload (in-material / out-material / move arrays) for work-order close |
| 6 | `BR_IM_INF_REG_ERP_MATERIAL_SEND` | `REG_ERP_IN_MATERIAL_SEND(...)` | 1269 | `2612/GetDataSet` | `INDATA,INMTRL` | `OUTDATA` | X | Send ERP material **input** (입고) |
| 7 | `BR_IM_INF_REG_ERP_MATERIAL_SEND` | `REG_ERP_OT_MATERIAL_SEND(...)` | 1348 | `2612/GetDataSet` | `INDATA,INMTRL` | `OUTDATA` | X | Send ERP material **output** (출고) |
| 8 | `BR_IM_INF_REG_ERP_MOVESTOCK_SEND` | `REG_ERP_MOVESTOCK_SEND(...)` | 1428 | `2612/GetDataSet` | `INDATA,INMOVE` | `OUTDATA` | X | Send ERP stock movement |
| 9 | `BR_IM_REG_PACK_CLOSE_ERP_SND` | `ErpPackSend(SECTION)` | 1573 | `2612/GetDataSet` | `INDATA_INIT,INDATA_MTRL` | `IN_INMTRL,OT_INMTRL` | R→X | Build ERP payload for packing close |
| 10 | `BR_IM_REG_WORKORDER_CLOSE_DIV_ERP_SND` | `ErpWorkorderSend(SECTION)` | 1671 | `2612/GetDataSet` | `INDATA_INIT,INDATA_MTRL,INDATA_PROD` | `IN_INMTRL,OT_INMTRL,IN_INPROD,OT_INPROD` | R→X | Build ERP payload for work-order close (division type) |
| 11 | `BR_IM_INF_REG_ERP_MATERIAL_SEND` | `REG_ERP_IN_WORKORDER_MATERIAL_SEND(...)` | 1800 | `2612/GetDataSet` | `INDATA,INMTRL` | `OUTDATA` | X | Work-order material input send |
| 12 | `BR_IM_INF_REG_ERP_MATERIAL_SEND` | `REG_ERP_OT_WORKORDER_MATERIAL_SEND(...)` | 1874 | `2612/GetDataSet` | `INDATA,INMTRL` | `OUTDATA` | X | Work-order material output send |
| 13 | `BR_IM_INF_REG_ERP_PROD_SEND` | `REG_ERP_IN_WORKORDER_PROD_SEND(...)` | 1950 | `2612/GetDataSet` | `INDATA,INITEM` | `OUTDATA` | X | Work-order product (생산실적) send |
| 14 | `BR_IM_PRD_SEL_WIPCOUNTACTHISTORY_WO_PROD` | `REG_ERP_IN_WORKORDER_PROD_SEND(...)` | 1987, 2043 | `2612/GetDataSet` | `INDATA` | `OUTDATA` | R | Check the ERP 101/102 전표번호 (document no.) after send |
| 15 | `BR_IM_PRD_SEL_WIPCOUNTACTHISTORY_WO_PROD` | `GETMBLNR_CHECK(pERP_PROD_RESULT)` | 2094 | `2612/GetDataSet` | `INDATA` | `OUTDATA` | R | Poll MBLNR (ERP document no.) |

### 3.3 Search / grid bizIDs (all via `CallBizJson.aspx/GetBizJsonByDictionary`)

| # | bizID | Called from | Line | inTableNames | outTableNames | Target grid |
|---|---|---|---|---|---|---|
| 16 | `BR_IM_SEL_WORKORDER_WIPCLOSEMONTH` | `Search_PostingDate()` | 3371 | `INDATA` | `OUTDATA` | posting-date validation |
| 17 | `BR_IM_PRD_SEL_WIPCOUNT_BY_EQSG` | `Search_WipCloseState()` | 3431 | `INDATA` | `OUTDATA` | WIP-close state grid |
| 18 | `BR_IM_PRD_SEL_ERPPOSTRESULT_WIP` | `Search_MainData_Detail1()` | 3543 | `INDATA` | `OUTDATA` | `ucWipRealgrid` (tab 1) |
| 19 | `BR_IM_PRD_SEL_WIPCOUNT_ERPPOSTRESULT_PROD` | `Search_MainData_Detail2()` | 3715 | `INDATA` | `OUTDATA` | `ucProductRealgrid` (tab 2) |
| 20 | `BR_IM_PRD_SEL_WIPCOUNT_ERPPOSTRESULT_WO` | `Search_MainData_Detail3(pAREAID)` | 3777 | `INDATA` | `OUTDATA` | `ucWorkorderRealgrid` (tab 3) |
| 21 | `BR_IM_PRD_SEL_WIPCOUNT_PACK_WIP` | `Search_MainData_Detail5()` | 3907 | `INDATA` | `OUTDATA` | `ucPackRealgrid` (tab 5) |
| 22 | `BR_IM_PRD_SEL_WIPCOUNT_STATE` | `Search_MainData_Detail4()` | 4094 | `RQSTDT` | `RSLTDT` | `ucWipCloseStatusRealgrid` (tab 4) |
| 23 | `BR_IM_PRD_SEL_WIPCLOSEACTHISTORY_ERP_LIST` | `Search_Erp_Snd_List(pERPType, pLOTID, pWOID)` | 4213 | `INDATA` | `OUTDATA` | `ucErpHistoryGrid` |

### 3.4 Combobox bizIDs

| bizID (sp_name) | Called from | Line | Purpose |
|---|---|---|---|
| `BR_IM_SEL_AREA_CBO` | `SetArea()` | 2146 | Plant / building |
| `BR_IM_SEL_PRODUCTGROUP_BY_AREA_CBO` | `SetGrade(record)` | 2208 | Product group |

---

## 4. Consolidated bizID list (distinct, active)

| bizID | Type | Used by |
|---|---|---|
| `BR_CUS_SEL_COMMONCODE_CBO_CMCODE` | BR / combo | 0240, 0240_1 |
| `BR_IM_COM_GET_COMMONCODE_CBO` | BR / combo | 0240 |
| `BR_IM_INF_REG_ERP_MATERIAL_SEND` | BR / X | 2612 (×4 call sites) |
| `BR_IM_INF_REG_ERP_MOVESTOCK_SEND` | BR / X | 2612 |
| `BR_IM_INF_REG_ERP_PROD_SEND` | BR / X | 2612 |
| `BR_IM_LMS_GET_EQPT_INSP_DAILY_INFO` | BR / R | 0239 |
| `BR_IM_LMS_REG_MEASURE_DATA` | BR / X | 0240 |
| `BR_IM_LMS_SEL_RTY_INFO` | BR / R | 0240 |
| `BR_IM_PRD_CHK_EXCELDATA` | BR / R | 0240_1 |
| `BR_IM_PRD_REG_EQUIPMENTNOTE` | BR / X | 0239 |
| `BR_IM_PRD_REG_LOT_PROD_LOTMATERIALHISTORY` | BR / X | 2612 |
| `BR_IM_PRD_REG_MEASREMENT` | BR / X | 0240, 0240_1 |
| `BR_IM_PRD_SEL_ERPPOSTRESULT_WIP` | BR / R | 2612 |
| `BR_IM_PRD_SEL_WIPCLOSEACTHISTORY_ERP_LIST` | BR / R | 2612 |
| `BR_IM_PRD_SEL_WIPCOUNTACTHISTORY_WO_PROD` | BR / R | 2612 |
| `BR_IM_PRD_SEL_WIPCOUNT_BY_EQSG` | BR / R | 2612 |
| `BR_IM_PRD_SEL_WIPCOUNT_ERPPOSTRESULT_PROD` | BR / R | 2612 |
| `BR_IM_PRD_SEL_WIPCOUNT_ERPPOSTRESULT_WO` | BR / R | 2612 |
| `BR_IM_PRD_SEL_WIPCOUNT_PACK_WIP` | BR / R | 2612 |
| `BR_IM_PRD_SEL_WIPCOUNT_STATE` | BR / R | 2612 |
| `BR_IM_PRD_UPD_WIPCLOSE` | BR / X | 2612 |
| `BR_IM_PRD_UPD_WIPCLOSE_PACK` | BR / X | 2612 |
| `BR_IM_REG_PACK_CLOSE_ERP_SND` | BR / R→X | 2612 |
| `BR_IM_REG_WORKORDER_CLOSE_DIV_ERP_SND` | BR / R→X | 2612 |
| `BR_IM_REG_WORKORDER_CLOSE_ERP_SND` | BR / R→X | 2612 |
| `BR_IM_SEL_AREA_CBO` | BR / combo | 0239, 0240, 2612 |
| `BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO` | BR / combo | 0239 |
| `BR_IM_SEL_EQUIPMENTSEGMENT_BY_PCGSID_CBO_FOR_MEASURE` | BR / combo | 0240 |
| `BR_IM_SEL_EQUIPMENT_SHOP_CBO` | BR / combo, R | 0239 (also server-side), 0240 |
| `BR_IM_SEL_PROCESSSEGMENT_BY_PCSGID_CBO` | BR / combo | 0239, 0240 |
| `BR_IM_SEL_PROCESS_BY_PCSGID_CBO` | BR / combo | 0239, 0240 |
| `BR_IM_SEL_PRODUCTGROUP_BY_AREA_CBO` | BR / combo | 0239, 0240, 2612 |
| `BR_IM_SEL_WORKORDER_WIPCLOSEMONTH` | BR / R | 2612 |
| `BR_IM_UPD_WORKORDER_CLOSE` | BR / X | 2612 |
| `DA_IM_BAS_SEL_EQUIPMENTSEGMENT_TBL` | DA / R | 0240 |
| `DA_IM_PRD_SEL_WIPCLOSE` | DA / R | 0240 |
| `DA_IM_SEL_PC_LIST` | DA / R | 0240 |
| `DA_IM_SEL_PERSON_BY_EQPT` | DA / R | 0239 |

Total: **38 distinct bizIDs** across the three screens.

---

## 5. Screen difficulty rating (1 = very easy … 5 = very hard)

Rated on: source size, number of bizIDs, dynamic/runtime-built grid schema, async chaining, external-system coupling, and blast radius if it breaks.

| Screen | Lines (aspx + cs) | biz call sites | Grids | Rating | Verdict |
|---|---|---|---|---|---|
| GMES_IMES_0239 | 897 + 397 | 4 | 1 (dynamic columns) | **3 / 5 — Medium** | |
| GMES_IMES_0240 (+ `0240_1`) | 1,926 + 93 (popup 1,489 + 69) | 6 + 5 popup + 9 `CallBizAjax` | 1 (schema swaps per measure item) | **4 / 5 — Hard** | |
| GMES_IMES_2612 | 6,243 + 128 | 23 | 6 (tabbed) | **5 / 5 — Very hard** | |

### GMES_IMES_0239 — 3 / 5 (Medium)

- Small aspx, only 3 client bizIDs; the search screen itself is simple.
- **What raises it above 2:** the real logic lives in `GMES_IMES_0239.aspx.cs:76` `GetDataList` — it calls two bizActors, pivots `OUTDATA_COL` rows into `COL_*` + `COL_*_COLOR` columns, adds `USERID/USERNAME/WORKER_NOTE`, and LINQ-groups `OUTDATA_INFO`. Grid columns are unknown until runtime, so a biz change silently reshapes the UI.
- There is also a dead `GetDataList_20211126` (cs:247) kept alongside the live one — easy to edit the wrong copy.
- Inline editing writes back through `BR_IM_PRD_REG_EQUIPMENTNOTE` on cell edit, so edits are not batched.

### GMES_IMES_0240 — 4 / 5 (Hard)

- The grid is rebuilt per measurement item (`CA/EE/MS/OA/PC/PQ/SD`) — `gridColSet(code)` plus six `onGetEditValue` overrides, and `ChangeItemGrid()` preloads **8** separate `CallBizAjax` result sets just to populate in-cell dropdowns.
- `SaveData()` spans lines 1524–1759 with per-item-type branching into one biz; `chkDeleteProc` builds a different payload for the same table.
- Composite key hacks: `TempEQPTID` is string-concatenated as `AREAID|EQSGID|SEPARATION_TYPE_NAME` and varies by item type (lines 1470–1476) — fragile and untypeable.
- The `0240_1` Excel popup adds ~1,500 lines with **seven** separate `reader.onload` parsers (one per item type) and duplicated `BR_IM_PRD_CHK_EXCELDATA` / `BR_IM_PRD_REG_MEASREMENT` call sites, including the `'INDATA, '` typo.
- Two stale copies (`GMES_IMES_0240.aspx.bak.txt`, `GMES_IMES_0240_backup.aspx.txt`) sit next to the live file.

### GMES_IMES_2612 — 5 / 5 (Very hard)

- 6,243 lines in one aspx, **23 bizIDs**, six grids across tabs, plus a progress-bar UI (`ShowProgressLoading` / `setProgress` / `CloseProgressLoading`) driving long-running work.
- ERP-coupled: a single close fans out into `ErpSend` → `REG_ERP_IN_MATERIAL_SEND` → `REG_ERP_OT_MATERIAL_SEND` → `REG_ERP_MOVESTOCK_SEND` → product send → `GETMBLNR_CHECK`, each an async callback nested in the previous one. There is no transaction across the chain, so a mid-chain failure leaves MES and ERP diverged.
- `BR_IM_INF_REG_ERP_MATERIAL_SEND` appears at four call sites with near-identical payload-building code — changes must be applied in all four.
- Three parallel close flows (pack / work order / division) each with their own validation function (`ErpPackSendValidation`, `ErpSendValidation`, `ErpSendProdValidation`), and a 670-line `InitMasterGrid()` (2278–2948).
- Highest blast radius of the three: this is month-end WIP close and ERP posting — errors are financial, and reversing an ERP 전표 is not a code fix.

**Recommended order if you are touching all three:** 0239 → 0240 → 2612.

---

*Note: the previous version of this file (screens 0203 / 0225 / 0226) was kept as `bizActor_0203_0225_0226.md`.*
