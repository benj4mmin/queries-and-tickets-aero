-- queries from cory and etc

--update tl set tl.transmitflag = '1'
--select *
from wms_transmitlog tl
join wms_orders wo on tl.key1 = wo.orderkey
where tl.tablename = "shipmentdockconfirm" --and tl.key2 = 'WAVE'
and wo.EXTERNORDERKEY in ('LT00001234', 'LT0001235')

-- use; to change server where query is ran
use lebanon

-- can also use inline database calls so you can switch between which one to use
-- in a single executable
select *
from lebanon.dbo.orders (nolock)
where customer_reference = 'LC0000746611'


-- select stmt; to choose what data to find in db
-- select top and select distinct cant be used in conjunction
select top 100 * from orders (nolock)
-- where clause; to filter what data is selected in said db
where customer_reference = '10000004258768300007'
select distinct * from Lineitem (nolock)
where orders_id = 31713026

--continuing giant unorganized compilation of query and sql snippets


--select stmt for report query to find wild card search using LIKE
select * from report where title like '%multiple%'

--# and @ are temp and the memory will clear after stor proc is completed
-- Set Date Range for the past 3 months
declare @startdate datetime
declare @enddate datetime

set @enddate = getdate()
set @startdate = dateadd(day, -90, getdate())

SET @startdate = CONVERT(datetime,CONVERT(varchar,@startdate,101) + ' 12:00:00 AM')
SET @enddate = CONVERT(datetime,CONVERT(varchar,@enddate,101) + ' 11:59:59 PM')

--example of temp usage with tables
-- Create Temo Table
create table #tmp ([Item#] varchar(50), [Description] varchar(60), CurrentInventory int, ReorderPoint int, Reord_Qty int, Item_ID int,
				   QTY_UOM float, StdDesc varchar(800), Packkey varchar(50), [Default_UOM] varchar(10), Item_Status varchar(30), 
				   DateLastOrdered datetime, TimesBelow int, AddDate datetime, POKey varchar(800), Open_Qty int, OpenPO int, Qty_Received float,
				   Qty_Ordered float, VendorName varchar(800), Notes varchar(800), GCAS varchar(800), SubSKU varchar(800), [3MonthUsage] int,
				   PO_Percent float)


-- Populate Temp Table
insert
	#tmp
select distinct  
	'Item#' = (i.primary_reference),
	'Description' = (i.short_desc), 
	'CurrentInventory' = (i.[@QtyAvailable]),
	'ReorderPoint' = (i.reorder_point), 
	'Reord_Qty' = (i.flexfield6),
	'Item_ID' = (i.item_id),
	'QTY_UOM' = (i.[@uomqty]), 
	'StdDesc' = (i.flexfield1),
	(i.packkey) as packkey,
	(i.default_uom) as default_uom,
	(i.item_status) as item_status,
	'DateLastOrdered' = (select top 1 o.Order_Date from orders o with (nolock), lineitem l  with (nolock) where l.item_id = (i.item_id) and l.orders_id = o.orders_id order by o.orders_id desc),
	--(select min(date_below) from Inventory_Reorder with (nolock) where item_id = i.item_id) as MinDateBelow, --m.hancock - 6/30/2008 4:34:37 PM - DELETE
	--(date_below) as MinDateBelow, 
	(select Count(*) from Inventory_Reorder with (nolock) where item_id = (i.item_id)) as TimesBelow,
	(p.AddDate) as adddate,
	(p.POKey) as POKey,
	(p.qty) as Open_Qty,
	(p.OpenPO) as OpenPO,
	(p.QtyReceived) as Qty_Received,
	(p.QtyOrdered) as Qty_Ordered,
	(I.flexfield23) as VendorName, --m.hancock - 1/21/2010 10:14:35 AM - CMR 20100121.003. Add vendor name to CPG Reorder report.
	(I.flexfield40) as 'Notes',	 --m.hancock - 7/30/2010 9:41:04 AM - CMR 20100726.003. Add notes field to reorder report.
	(I.flexfield16) as 'GCAS',		 --m.hancock - 6/23/2011 11:25:12 AM - 20110621.005. Added GCAS Number (Inventory flexfield16)

	-- DGY 2/9/13 -- 20130207.006
	'SubSKU' = isnull((i.FlexField11), ''),
	'3MonthUsage' = isnull((select 
								sum(le.qty_shipped)
							 from
								lineitemedit le with (nolock)
							 inner join
								ordersedit oe  with (nolock) on le.orders_id = oe.orders_id
							 where
								le.line_status = 'SHIPPED'
								and oe.ship_date between @startdate and @enddate
								and le.item_id = i.item_id), 0),
	00.00
from
	InventoryEdit i with (nolock)
left outer join 
	Mason_CPG_ReorderReport p with (nolock) on p.sku = i.primary_reference
--left outer join 
--	Inventory_Reorder IR (nolock) on I.item_id = IR.item_id --m.hancock - 6/30/2008 4:22:41 PM - Add Inventory_Reorder
--left outer  join
--	wms_PODETAIL po with (nolock) on i
where
	i.[@QtyAvailable] < i.reorder_point
	and i.reorder_point > 0
	and I.[shared@fulfillment_id] = @fulfillment_id --m.hancock - 3/5/2010 9:08:57 AM - Remove duplicates due to sharing inventory with children
	and i.flexfield20 = 'n' --obsolete
	and i.item_type <> 'CONVENIENCE KIT'
	--and (p.QtyOrdered is null or p.QtyOrdered <> '0')
	and case when @fulfillment_id = 73 then i.item_status else 'DELETED' end <> 'DELETED' --m.hancock - 12/8/2008 4:23:28 PM - CMR 20081208.001; Remove DELETED item status for CPG
	--and (isnull(p.QtyReceived*100,0)/case when (p.qtyordered) = 0 then 1 else isnull(p.QtyOrdered,1) end < 98 ) --j.norton cmr 20121012.004 - remove PO's that have been closed out by implementing CPG's 98% rule. 
	AND ISNULL(Reference_2,'') <> 'Y' -- Skipped items should not be on the report RT 07/29/2014
order by
	i.primary_reference


--select stmt from filipe to query orders that were shipped already and sent receipts but cx had issues on their end for receiving receipts
select orders_id, order_status from LEBANON.dbo.orders where customer_reference in ('TAOS00696627','TAOS00696924',
'TAOS00697029','TAOS00702280','TAOS00702495','TAOS00703998','TAOS00704001','TAOS00704101','TAOS00704008','TAOS00704104',
'TAOS00704110','TAOS00704017','TAOS00704060OG','TAOS00704305OG','TAOS00704244OG','TAOS00704316OG','TAOS00704255OG',
'TAOS00704342','TAOS00704343','TAOS00704347','TAOS00704348','TAOS00704349','TAOS00704350OG')

-- update stmt from filipe that sets the queried orders back to 0 before we can send them out again through boomi
update lebanon.dbo.Fulfillment_Transaction set trans_status = 0 where trans_key01='36688813' and trans_submodule='SHIPPED'

-- update stmt from filipe that after querying allows boomi to send out xml again to provide receipt for cx
update t set t.trans_status=0 from lebanon.dbo.Fulfillment_Transaction t 
inner join LEBANON.dbo.orders o on t.trans_key01=o.orders_id
where t.trans_submodule='SHIPPED' and 
o.customer_reference in ('TAOS00696627','TAOS00696924','TAOS00697029','TAOS00702280','TAOS00702495','TAOS00703998','TAOS00704001','TAOS00704101','TAOS00704008','TAOS00704104','TAOS00704110','TAOS00704017','TAOS00704060OG','TAOS00704305OG','TAOS00704244OG','TAOS00704316OG','TAOS00704255OG','TAOS00704342','TAOS00704343','TAOS00704347','TAOS00704348','TAOS00704349','TAOS00704350OG')

---------------------------------------------------------------------------------------------------
--8/27/18 need to crunch numbers for some goals and estimates for some tickets and projects at work.


-- select for grabbing quantities and etc using storerkey from wms_receiptdetail

SELECT TOP 4 *
FROM wms_RECEIPTDETAIL (nolock)
WHERE STORERKEY = 'ras'
ORDER BY SERIALKEY DESC

--keep updates like this always in comments until ready. set and where portion arent execute statements so they arent as dangerous to leave uncommented

--update wms_orderdetail
set shelflife = -1
where EXTERNORDERKEY in ('RA0000038510', 'RA0000038512', 'RA0000038479')
and sku = '81502828'
-- make sure case ids match using manifest
select *
from vw_Manifest (nolock)
where caseid = 	'0070575505'

-- snippet of store proc or batch update

/*
IF @@ROWCOUNT > 0 
BEGIN
	-- Get Batch Reference
	EXECUTE Sequence_NextVal @batch_id OUTPUT,'BATCH',1
	INSERT INTO Batch(batch_id,fulfillment_id,batch_type,batch_date,batch_reference,batch_status)
		VALUES (@batch_id,@fulfillment_id,'TRANSACTIONS',@enddate,@batch_reference,'0')
END
*/

-- query from james to work on stuck shipment due to pick status

--To get the orderkey
select * from wms_orders 
where externorderkey like 'lt%1253642'

--Query to get the lot, loc, and id information.
select * from wms_PICKDETAIL
where orderkey = '0014475039' and status < 9


--Check to see if there is any inventory in this location
select * from wms_lotxlocxid
where lot = '0000257879'  and id = '0070375746'
--There was none for this location which means Infor failed to move qty.

--Since there is no qty in the PICKTO location, we must update the pickdetail back to the original location.  Thankfully, we can get this from the "fromloc" field.  Also, the status must match with the order detail.
update wms_PICKDETAIL
set loc = FROMLOC, id = '', status = 1
where orderkey = '0014475039' and status < 9


--Run this to fix the allocation buckets.
exec scprd.[wmwhse1].[pr_Process_FixAllocations] 'CDL', 'P92586'


/*** error message in SQL

Msg 245, Level 16, State 1, Line 3
Conversion failed when converting the varchar value 'SC318LVL3' to data type int.
-- this occurs when you dont tag your varchars/strings with ''

***/
-- finding a part and starting process to look for how the UOM could be getting changed
--
select *
from inventory (nolock)
where primary_reference = '83526212'
--part info
-- item_id 394807
-- item_type PART
-- fulfillment_id 1088
-- short desc CU SKII MIX 30CT GIFT SET
-- default_uom CS
-- edit_who tracy esseck
-- packkey 1EA.2PK.30CS


-- template for notating store procs or just anything i build in general

/*
	Programmer:	venkat	
	Create Date:	03/25/2003
	Description:	To display the name of the inventory kit containing the inventory item, and the number and quantity of the specified item used in the kit.
	Date Modified:	05/01/03
	Programmer:	Glenn Burton
*/
 or 

/***** New store proc for BARD Returns *****/
/***** Version 1.0: 9/11/2018	Ben Y  *****/
/***** Used for return reports for BARD*****/
/***** Ticket: ATP-12565			   *****/

-- used to find most recent reports made
select top 2 *
from report (nolock)
order by report_id desc


-- updates report to have correct values in these fields
--update-- report
set [type] = 'CORELEBANON', category = 'RETURNS'
where report_id = 2964


-- steps for creating new storproc
create new stored PROC
in SQL using 
Create Procedure [dbo].[pr_Report_InventoryReturnedOrder_WithArchive]
after creating a report (at least one to test with)
go to afsweb204 content wwwroot eReports and find old version to replace
copy it DO NOT OPEN IT MAY BE IN USE CURRENTLY
copy into personal folder then drag into/open crystal reports 
now we override old reports data with new report BY
clicking database in navbar then set datasoure LOCATION
click + symbols to open folders in top and bottom half of screen
follow path for bottom afssql01 dbo reports 
then click your newly saved report and highlight main report in top half
click update in right side COLUMN
MAKE SURE YOU SAVE in crystal now that new report is in it
next we head back to sql
and go to enterprise in databases
and find the reports table and right click then select edit top 200
click very bottom which will populate a new row 
type in the 4 fields require BEFORE typing active into status 
fields are title (same as store proc) name (same) 
type and category 
then set as active
and save 
now we go to RDM and log into afsterm01 to fairfield windows nav 
select bard fulfillment then click manage reports 
scroll to bottom and click bottom row to open new row and in dropdown menu 
select the new report that sql added to windows nav 
once selected set permissions and hit SAVE and double check that it saved those users
go to prod nav and to bard reports and should see new report and test 
to make sure all the report types work


-- used this query to find more info on IRE order needing a receipt
-- first query found externreceipt key i needed and the date so i could 
-- find the doc in boomi
select top 50 *
from wms_RECEIPT_All
where STORERKEY = 'IRE'

-- or this to find orderkey and externorderkey
select top 50 *
from wms_ORDERS_All
where STORERKEY = 'PRB'

-- or shortcut not filtering much to get a wave key in general to test

select *
from wms_wavedetail_all wd (nolock)
join wms_orders o (nolock) on o.orderkey = wd.orderkey
where o.STORERKEY = 'PRB'


-- serialkey for ire externreceiptkey 259 is 43529
-- didnt need sk as much as receiptdate

-- query to find details on waves pulls from wavedet and orders both wms
select *
from wms_wavedetail_all wd (nolock)
join wms_orders o (nolock) on o.orderkey = wd.ORDERKEY
where wd.wavekey = '0000321592' --add 0's if they only give '123456'

-- notes on wave not printing sykes ticket ATP-12689
-- james gave these 2 paths for scripts to run to check where the errors are
-- and to open the xml
-- \\afsweb204\Content\Navigator\Templates\XMLPrintDocuments\PGK\
-- \\afsweb204\Content\Navigator\Templates
-- try printing through nav under warehouse then print wave documents
-- paste wave  -- DONT PRINT AT SAME TIME AS OTHERS
-- usually an error in file not code


-- query to find reports specifically. courtesy of james #report
SELECT f.[fulfillment_id], f.short_name, f.[long_name], fr.[report_id], r.name, r.title, r.category, r.[type]
      , fr.[sequence], fr.[role_ids], fr.[report_format], fr.[ExcelAreaType], fr.[ExcelAreaGroupNumber], fr.[RunCounter], fr.[LastRunDate], fr.[description], fr.[title]

FROM   [ENTERPRISE].[dbo].[Fulfillment_Report] fr -- This table stores what reports are assigned to which fulfillments.
              join ENTERPRISE.dbo.Report r on fr.report_id = r.report_id -- This table stores all the reports.
             join ENTERPRISE.dbo.Fulfillment f on fr.fulfillment_id = f.fulfillment_id -- I joined this table just to get the short and long name of the fulfillment.
where f.fulfillment_id = 986 --find a ffid to utilize this
ORDER BY f.fulfillment_id, r.category, fr.report_id

-- short version of above ^^^^^^^^ to just get names with rep id

select f.short_name, f.[long_name],r.[name],r.title, fr.*
from [ENTERPRISE].[dbo].[Fulfillment_Report] fr -- This table stores what reports are assigned to which fulfillments.
  join ENTERPRISE.dbo.Report r on fr.report_id = r.report_id -- This table stores all the reports.
  join ENTERPRISE.dbo.Fulfillment f on fr.fulfillment_id = f.fulfillment_id
where fr.report_id = 494 -- where rep id is

-- james showed me how to create cert in boomi
-- and then deploy to UAT to ensure extensions are set and addresses are correct
-- in boomi click green 'new' button top left main window
-- select type 'certificate'
-- set name and folder
-- deploy to UAT2
-- go back into process and make sure SSL extension set
-- 

#BSY #crystal 
SQLDU01\UAT
AEROSSA
AEROSQL

-- another fix stuck shipment
-- CHECK WMS ... if it didnt make it there check nav
-- SELECT *
-- FROM wms_orders (nolock)
-- wHERE externorderkey like '%FT%3844699%'
-- in boomi process rep filter under documents and paste order #
-- executions dropdown documents ^^ tracked fields ^^ key field
select *
from LEBANON.dbo.orders (nolock)
where primary_reference = 'FT0003844699'
select *
from 
-- ship addy had invalid characters on end update to fix
--update LEBANON.dbo.orders
set ship_address_1 = '16915 GEORGE WASHINGTON DR'
where primary_reference = 'FT0003844699'

-- once addy is fixed we update trans status once released
--update Fulfillment_Transaction 
set trans_status = 0
where trans_key01 = '37100957'
and trans_submodule = 'released'


-- 12729 needed to check correct time in boomi process
-- showed as blank during 9:00 am for 8:55 submit
-- re ran docs

-- 12731 item was entered into coty inventory but not their catalog
-- so search or order wouldnt find it

-- notes on josh helping with vay 856 issue
-- we had to go to where the orders were being imported
-- aka vay order import process
-- look in map to check what flexfields being used and what may
-- be shared between 2 parallel processes doing ship confirms
-- getting one null one blank meaning para processes each giving one of those
-- hard code in map to set a distinction from one process to another with 
-- flexfield 6 or 7
-- test with previous order, grab from last process that ran
-- that actually has a starting file and download this file and copy
-- into vayyar in folder in winscp or filezilla
-- now test process with new field in UAT atom 02 aka UAT AS2 -test ----- UAT01
-- change get to pull from orders_flexfield ox
-- example 
select top 200 *
from Orders o (nolock)
inner join Orders_FlexFields ff (nolock) on ff.orders_id = o.orders_id
where o.fulfillment_id = '1162'
order by o.orders_id desc


update Orders_FlexFields
set flexfield6 = 'VAY_XML_ORDER'
where orders_id = '31749309'
-- hard coded the vay xml order in ff6
-- will hard code vay edi order in ff6 for other process to separate them from 856
-- this test was done in UAT first on a test order that was already shipped
-- go into process and open the get to open source code and copy paste to SQL
-- in sql (test) we changed this
SELECT 
o.consign,
o.customer_reference,
o.email,
i.primary_reference AS "item_primary_reference",		
l.line_number,
line_status = case 
		when l.line_status in ('ERROR','CANCELED','SKIPPED') then 'CANCELED'
		--else line_status=SHIPPED...
		when l.qty_shipped=0 and l.qty_backordered>0 then 'BACKORDERED' --11/22/2013
		when l.qty_shipped=0 then 'CANCELED' 
		when l.qty_shipped < l.qty_ordered then 'PARTIAL' --01/20/2014
		else 'SHIPPED' end,
o.order_date,
order_status = dbo.BACKORDERSTATUS(o.orders_id,o.order_status), --11/22/2013 added to show if backordered
o.phone,
o.primary_reference AS [Order Primary Reference],
convert(int,(l.qty_ordered / ISNULL(pd.units,1))) AS qty_ordered,
convert(int,(l.qty_shipped / ISNULL(pd.units,1))) AS qty_shipped,		
o.ship_address_1,
o.ship_address_2,
o.ship_attention,
o.ship_city,
o.ship_country,
o.ship_date,
o.ship_postal_code,
o.ship_region,
shipmethod = sm.description,
m.trackingnumber,
ft.trans_id,
l.qty_backordered	
FROM Orders o (nolock)
inner join Orders_FlexFields ox (nolock) on ox.orders_id = o.orders_id -- added this to call ff
INNER JOIN Fulfillment_Transaction ft(nolock) ON o.orders_id = ft.trans_key01
--INNER JOIN Orders_Batch ob(nolock) ON o.orders_id = ob.orders_id
--INNER JOIN Batch b(nolock) ON ob.batch_id = b.batch_id
INNER JOIN Lineitem l(nolock) ON o.orders_id = l.orders_id
INNER JOIN Lineitem_Flexfields lx(nolock) ON l.lineitem_id = lx.lineitem_id
INNER JOIN Ship_Method sm (nolock) ON o.ship_method_id = sm.ship_method_id
INNER JOIN Inventory i(nolock) ON l.item_id = i.item_id
LEFT OUTER JOIN Inventory_PackDetail pd(nolock) ON i.packkey = pd.packkey AND i.default_uom = pd.uom
LEFT OUTER JOIN vw_Manifest m(nolock) ON o.primary_reference = m.order_primary_reference
WHERE o.fulfillment_id = 1162
	AND ft.trans_module = 'ORDERS'
	AND ft.trans_submodule IN ('SHIPPED','ERROR','CANCELED','SKIPPED')
	and ox.flexfield6 = 'VAY_XML_ORDER'  -- added to filter where using this ff 
	--AND ft.trans_status = '0'
	AND o.order_source Not In ('Windows')
        AND o.ship_date >= '6/9/2018'
	--AND b.external_batch_id = 'VAYFF'
ORDER BY o.customer_reference, l.line_number 

-- after adding these and setting up the sql in boomi itll no longer need
-- to provide a stored proc and giving us better vision
-- on version control
-- save and close all the updates after double checking the fields
-- in the GETs didnt change within boomi
-- save process
-- test again
-- with good results can use prod
-- 
-- fulfillment trans_status = 0  ie. AND ISNULL(f.trans_status,'0') = '0'
-- needs to be entered in everty outbound data feed

--- transkey01 is for the order header
--- so if you put in the orders_id in the trans_key02, you will get lineitem info
--- if you put in the orders_id in the trans_key01, you will get the order info

-- used in troubleshooting and resetting trans_status and other flags
-- for orders Judy needed for VAY 856 processes

select *
from ordersedit (nolock)
where primary_reference in ('VA0000027883','VA0000027884','VA0000028709','VA0000028710')

select *
from Fulfillment_Transaction ft (nolock)
where trans_key01 in ('37106896',
'37106897',
'37140075',
'37140076')
and trans_submodule = 'shipped'

--update ft
set trans_status = 0
from Fulfillment_Transaction ft (nolock)
where trans_key01 in ('37106896',
'37106897',
'37140075',
'37140076')
and trans_submodule = 'shipped'


select *
from lineitem (nolock)
where orders_id = '36994553'

--update o
set flexfield6 = 'VAY_EDI_ORDER', flexfield30 = 'EDI850'
from ordersedit o (nolock)
where primary_reference in ('VA0000027883','VA0000027884','VA0000028709','VA0000028710') 

SELECT ls.*
	FROM SCPRD.wmwhse1.LTLShipment ls with (nolock)
	INNER JOIN SCPRD.wmwhse1.LTLShipmentPallet lp with (nolock)
		ON ls.shipmentkey = lp.shipmentkey
	INNER JOIN SCPRD.wmwhse1.Pickdetail pd with (nolock)
		ON lp.palletkey = pd.dropid
	INNER JOIN SCPRD.wmwhse1.Orders wo with (nolock)
		ON pd.orderkey = wo.orderkey
where wo.EXTERNORDERKEY in ('VA0000027883','VA0000027884','VA0000028709','VA0000028710') 

-- taken from google search
-- select max usage 
select *
from orders o (nolock)
where o.add_date = (select MAX(add_date) from orders (nolock) where fulfillment_id = 1091);

-- use for stuck shipments that need to be deleted to check status

select *
from orders (nolock)
where primary_reference in (
'LG0000010899',
'LG0000010901',
'LG0000010903',
'LG0000010905',
'LG0000010908',
'LG0000010909',
'LG0000010914',
'LG0000010917',
'LG0000010918',
'LG0000010922')

select *
from Lineitem
where orders_primary_reference in (
'LG0000010899',
'LG0000010901',
'LG0000010903',
'LG0000010905',
'LG0000010908',
'LG0000010909',
'LG0000010914',
'LG0000010917',
'LG0000010918',
'LG0000010922')
-- afterwards use [dbo].[pr_Delete_Order_Everywhere] 'order#' one order per

-- use to put pick tickets into UAT to test with UAT orders
-- copy a current pick ticket then rename the copy with suffix _UAT
-- put this copy into prod folder
-- search for report id using like the original pick ticket name
-- we update the prod version IN SQLDU01 NOT AFS only because they are in
-- same folder and we will still have prod version in afs
-- but only new with suffix will be in UAT

select *
from report (nolock)
where [name] like '%ForwardPick%'

-- set UAT report name to include _UAT suffix to have in UAT 

--update r
set [name] = 'ForwardPick_UAT.rpt'
from report r (nolock)
where report_id = 494

-- do each section in correct order and by AWI or AFI dont mix these EOM procs
-- do one to completion before moving on
re run validation queries
/*
check date
run stored proc under A1 section
run 3 select queries 1 by 1
go to boomi and run tax export on afssql01
refresh and make sure it ran - if it got files out then we need to run 
the tax import
after tax import refresh and make sure it pulled files
can check filezil to see inbound caught the tax file by datetime or wait 2 min
run the query next in list and dont include whats after select not in parens
next section is a4 -- run the proc that says new if errors rerun with reset proc instead
after store proc run these 3 queries 1 by 1
last query should have no results if working properly
all thats left is running boomi master process
execute process in boomi under awi or afi ar-gl master
once this runs we need to run the send processes 1 by 1 on afssql02 
search awi or afi ar send then exec then search and run the gl send
get file from master process and email zip to kelly
email clients that process is completed!
*/

/*
use LEBANON

select *
from orders o (nolock)
inner join Orders_FlexFields ox (nolock) on ox.orders_id = o.orders_id
inner join Fulfillment_Transaction ft (nolock) on ft.trans_key01 = o.orders_id
where o.order_source = 'API'
--and ft.trans_module = 'ORDERS'
--and ft.trans_submodule <> 'SHIPPED'
and order_status <> 'SHIPPED'
--and ft.trans_status = 0
 and ISNULL(ox.flexfield30, '') <> 'EDI850'
and o.fulfillment_id = '1162'

select distinct order_source
from orders o (nolock)
inner join Orders_FlexFields ox (nolock) on ox.orders_id = o.orders_id
where-- o.order_source = 'API'
 ISNULL(ox.flexfield30, '') <> 'EDI850'
and o.fulfillment_id = '1162'


select flexfield30, o.*
from orders o (nolock)
inner join Orders_FlexFields ox (nolock) on ox.orders_id = o.orders_id
where customer_reference = 'CA-00041046'

use LEBANON
begin tran
select flexfield6, o.*
from orders o (nolock)
inner join Orders_FlexFields ox (nolock) on ox.orders_id = o.orders_id
inner join Fulfillment_Transaction ft (nolock) on ft.trans_key01 = o.orders_id
where o.order_source = 'API'
and ft.trans_module = 'ORDERS'
and ft.trans_submodule = 'SHIPPED'
and ft.trans_status = 0
 and ISNULL(ox.flexfield30, '') <> 'EDI850'
and o.fulfillment_id = '1162'
UPDATE       Orders_FlexFields
SET                flexfield6 = 'VAY_XML_ORDER'
FROM            Orders INNER JOIN
                         Orders_FlexFields ON Orders_FlexFields.orders_id = Orders.orders_id INNER JOIN
                         Fulfillment_Transaction AS ft ON ft.trans_key01 = Orders.orders_id
WHERE        (Orders.order_source = 'API') AND (ft.trans_module = 'ORDERS') AND (ft.trans_submodule = 'SHIPPED') AND (ft.trans_status = 0) AND (ISNULL(Orders_FlexFields.flexfield30, '') <> 'EDI850') AND (Orders.fulfillment_id = '1162')
select flexfield6, o.*
from orders o (nolock)
inner join Orders_FlexFields ox (nolock) on ox.orders_id = o.orders_id
inner join Fulfillment_Transaction ft (nolock) on ft.trans_key01 = o.orders_id
where o.order_source = 'API'
and ft.trans_module = 'ORDERS'
and ft.trans_submodule = 'SHIPPED'
and ft.trans_status = 0
 and ISNULL(ox.flexfield30, '') <> 'EDI850'
and o.fulfillment_id = '1162'
rollback
*/

-- corys help with updating report values with data from existing reps
-- into new reps
SELECT TOP (1000) [report_id]
      ,[title]
      ,[name]
      ,[path]
      ,[status]
      ,[category]
      ,[type]
      ,[printer]
      ,[papersize]
      ,[long_running]
      ,[use_rpt_connection]
      ,[rpt_User]
      ,[rpt_Pwd]
      ,[description]
  FROM [ENTERPRISE].[dbo].[Report]
  where report id -- like all the ids i have

insert into report
select
       [title] + 'Test'
      ,left([name], len([name]) -4) + '_UAT.rpt'
      ,[path]
      ,[status]
      ,[category]
      ,[type]
      ,[printer]
      ,[papersize]
      ,[long_running]
      ,[use_rpt_connection]
      ,[rpt_User]
      ,[rpt_Pwd]
      ,[description]
  FROM [ENTERPRISE].[dbo].[Report]
  where report_id -- like all the ids i have

-- from josh to help with identifying issue with allotments.
-- first shows sums of orders in specific statuses

select wp.sku, wp.[status], sum(qty)
from lineitem l (nolock)
inner join wms_orderdetail wo on wo.externorderkey = l.order_primary_reference and wo.EXTERNLINENO = l.line_number
inner join wms_PICKDETAIL wp on wp.ORDERKEY = wo.ORDERKEY and wp.ORDERLINENUMBER = wo.ORDERLINENUMBER
where l.item_primary_reference = 'PWR1002'
and l.fulfillment_id = 311
--and wp.[status] > 10 and wp.[status] < 35
group by wp.sku, wp.[status]
--1 not started 5 picked 6 packed 9 shipped

select o.[status], wp.*
from lineitem l (nolock)
inner join wms_orderdetail wo on wo.externorderkey = l.order_primary_reference and wo.EXTERNLINENO = l.line_number
inner join wms_PICKDETAIL wp on wp.ORDERKEY = wo.ORDERKEY and wp.ORDERLINENUMBER = wo.ORDERLINENUMBER
join wms_orders o on o.orderkey = wo.orderkey
where l.item_primary_reference = 'PWR1002'
and l.fulfillment_id = 311
and wp.[status] = 9
--and wp.[status] > 10 and wp.[status] < 35

/* ---------------------------------------------------------- */
-- SCRIPT SECTION
-- script to add order to manifest

--DROP TABLE #ORD

CREATE TABLE #ord(orders_id int)

INSERT INTO #ord
SELECT o.orders_id
FROM Orders o with (nolock)
WHERE o.parent_short_name = 'RAS'
and o.primary_reference = 'RA0000015710'
    --AND o.order_source = 'BATCH'

UPDATE l SET line_status = 'SHIPPED', qty_open = 0,qty_submitted=0, qty_shipped = l.qty_ordered
FROM Lineitem l
INNER JOIN #ord o
    ON l.orders_id = o.orders_id
WHERE l.order_primary_reference = 'RA0000015710'
    AND l.line_status <> 'SKIPPED'
--WHERE o.parent_short_name = @shortname
--and o.orders_id = @orders_id

INSERT INTO Manifest([trackingnumber]
          ,[caseid]
          ,[order_primary_reference]
          ,[void]
          ,[weight]
          ,[charge]
          ,[sur_charge]
          ,[packages]
          ,[bol]
          ,[carrier]
          ,[service]
          ,[thirdpty]
          ,[cod_package_flag]
          ,[consignee_residential_flag]
          ,[saturdaydelivery_flag]
          ,[oversize_flag]
          ,[bill_flag]
          ,[signature_flag]
          ,[aro_consignee_billing_flag]
          ,[aro_freight_collect_flag]
          ,[tran_date]
          ,[ship_date]
          ,[status]
          ,[add_date]
          ,[edit_date]
          ,[add_who]
          ,[edit_who]
          ,[billing_period]
          ,[billing_status])
SELECT distinct RIGHT('0000000000' + CONVERT(varchar(10),pd.CASEID),10)
AS [trackingnumber]
     ,--LEFT(o.primary_reference,2) + RIGHT('00000000' + CONVERT(varchar(10),o.orders_id),8)
      pd.CASEID as [caseid]
     ,o.primary_reference AS [order_primary_reference]
     ,'N' AS [void]
     ,isnull(o.ship_weight, 5.000) AS [weight]
     ,isnull(o.ship_chg, 0.000) AS [charge]
     ,0 AS [sur_charge]
     ,1 AS [packages]
     ,'' AS [bol]
     ,sm.service_name AS [carrier]
     ,sm.carrier_code AS [service]
     ,'N' AS [thirdpty]
     ,sm.COD_PACKAGE_FLAG AS [cod_package_flag]
     ,sm.CONSIGNEE_RESIDENTIAL_FLAG AS [consignee_residential_flag]
     ,sm.SATURDAYDELIVERY_FLAG AS [saturdaydelivery_flag]
     ,sm.OVERSIZE_FLAG AS [oversize_flag]
     ,sm.BILL_FLAG AS [bill_flag]
     ,sm.SIGNATURE_FLAG AS [signature_flag]
     ,sm.ARO_CONSIGNEE_BILLING_FLAG AS [aro_consignee_billing_flag]
     ,sm.ARO_FREIGHT_COLLECT_FLAG AS [aro_freight_collect_flag]
     --,0 AS [aro_delivery_confirmation_flag]
     ,GETDATE() AS [tran_date]
     ,GETDATE() AS [ship_date]
     ,'0' AS [status]
     ,GETDATE() AS [add_date]
     ,GETDATE() AS [edit_date]
     ,'M4239' AS [add_who]
     ,'Cleanup' AS [edit_who]
     ,'' AS [billing_period]
     ,'0' AS [billing_status]
FROM Orders o
INNER JOIN #ord d
    ON o.orders_id = d.orders_id
Inner join Ship_Method sm (nolock) on sm.ship_method_id = o.ship_method_id
inner join wms_ORDERS wo (nolock) on wo.EXTERNORDERKEY = o.primary_reference
inner join wms_PICKDETAIL pd (nolock) on pd.orderkey = wo.orderkey
WHERE o.primary_reference = 'RA0000015714'


--select * FROM MANIFEST WHERE ORDER_PRIMARY_REFERENCE = 'FT0002941213'
--select * FROM lineitem where orders_id = 27647748
--select * From ship_method

--In case anyone needs it in the future... heres a stored proc for testing UCC128 crystal reports.
-- this version of the stored proc hits the archive database, enabling you to test with old orders
-- that are no longer in Infor and are no longer on a wave (use the wavekey from pickdetail records).

[pr_Report_UCC_LTL_Labels_ARCdata_Test]


select top 10 *
from Inventory (nolock)
where item_id like '%435'

select *
from Orders (nolock)
where primary_reference= 'UT0000002653'
or primary_reference = 'UT0000002629'

select *
from Lineitem (nolock)
where orders_id = 36912582
and item_primary_reference = '81480037'

select *
from Lineitem_Transaction (nolock)
where item_id = 381930
order by add_date

select *
from wms_ITRN_All (nolock)
where SKU = '81480037'
order by EFFECTIVEDATE

-- query and update used to cancel / set order status to 9 so the orders dont get shipped
-- for ticket ATP-12889
select l.*, o.*
from LEBANON.dbo.orders o (nolock)
inner join lebanon.dbo.Lineitem_Backorders l (nolock) on l.original_orders_id = o.orders_id
where o.backorder_status = 'BACKORDERED'
 and o.add_date < '09-01-2018 00:00:01'
 and order_status = 'SHIPPED'
 and l.backorder_status <> 9
 and fulfillment_id = 686
order by o.add_date desc

--update l
set l.backorder_status = 9
from LEBANON.dbo.orders o (nolock)
inner join lebanon.dbo.Lineitem_Backorders l (nolock) on l.original_orders_id = o.orders_id
where o.backorder_status = 'BACKORDERED'
 and o.add_date < '09-01-2018 00:00:01'
 and order_status = 'SHIPPED'
 and l.backorder_status <> 9
 and fulfillment_id = 686


select *
from lebanon.dbo.Lineitem_backorders (nolock)
where backorder_status <> 9

--next
--


  select *
  from mason.dbo.wms_sku (nolock)
  where STORERKEY = 'PAY'

  --update s
  set CARTONGROUP = 'PAY'
  from mason.dbo.wms_sku s (nolock)
  where STORERKEY = 'PAY'

  /* ticket atp-12934
  had to use shopify login for TLE EPIC to use their interface and see what orders were open or unfulfilled ||||||||||||||||||||||||||||||||||
  then queried individual orders using this -- more notes below query 										vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

select *
from Fulfillment_Transaction (nolock)
where trans_id = '1238328611'

select *
from orders o (nolock)
join Lineitem l (nolock) on l.orders_id = o.orders_id
where o.orders_id = '37458341'


select *
from orders o (nolock)
join Lineitem l (nolock) on l.orders_id = o.orders_id
where o.reference_3 = '1139'
and o.cost_center = 'EPIC'
/* order id on site was actually ref 3 as seen in query. we then check the line item status and open/ordered/backordered quantities to see that
all the unfulfilled orders were due to items on backorder. and all the open orders were orders still in allocated status and some line items are lineitem status = shipped due
to being on backorder and therefor this order would be part-shipped.

/* ticket ATP-12934 and others involving any shopify
this is the base get for released orders in shopify for boomi process
*/

SELECT
	ft.trans_id,
	o.customer_reference				AS 'customer_order_id',
	lf.flexfield20						AS 'customer_lineitem_id', --whatever flex identifier they use?
	l.qty_ordered					AS 'qty_ordered',
	l.qty_ordered - l.qty_backordered	AS 'qty_accepted',
	l.qty_backordered				AS 'qty_backordered'
FROM orders o with (nolock)
INNER JOIN lineitem l with (nolock)
	ON l.orders_id = o.orders_id
INNER JOIN lineitem_flexfields lf with (nolock)
	ON l.lineitem_id = lf.lineitem_id
INNER JOIN Fulfillment_Transaction ft with (nolock)
	ON o.orders_id = ft.trans_key01
WHERE o.fulfillment_id = 901 --specific ffid
	AND ft.trans_module = 'Orders'
	AND o.cost_center = 'EPIC'
	AND ft.trans_submodule = 'RELEASED'
	and isnull(ft.trans_status02, 0) = 0
	--AND ft.trans_date BETWEEN ? AND ?
	AND l.qty_ordered - l.qty_backordered > 0
        AND l.parent_line_number IS NULL
ORDER BY o.orders_id DESC


-- ticket atp-12959 please verify ket allocations
--
select *
from mason.dbo.orders (nolock)
where primary_reference = 'KB0000143555'
 -- o id 37243707
select *
from mason.dbo.OrdersEdit (nolock)
where primary_reference = 'KB0000143555'

select *
from mason.dbo.lineitem (nolock)
where orders_id = '37243707'

select *
from mason.dbo.wms_SKUXLOC s(nolock)
join mason.dbo.wms_lot l(nolock) on l.SKU = s.SKU
where s.sku = '14715'
--and s.loc = '181011162'
and s.qty > 0
 /* help from cory to identify the allocation strategy can dive deeper possibly using fulfillment_transactions.
issue was also seen in infor since the item shows classic alloc and new alloc.*/
select*
from mason.dbo.wms_SKU s(nolock)
left join mason.dbo.wms_LOTXLOCXID li (nolock) on li.SKU = s.sku
where s.STORERKEY = 'KET' 
--and s.sku = '14715'

select *
from --mason.dbo.wms_SKUXLOC s(nolock)
 mason.dbo.wms_lot l(nolock) -- on l.SKU = s.SKU
where l.sku = '14715'

select *
from mason.dbo.wms_lot (nolock)
where STORERKEY = 'KET'
and ADDDATE > '2018-03-17'
order by [status]

-- update stmt used to put right alloc strat on all items missing it

--update s
set newallocationstrategy = 'N01',
	strategykey = 'NULL'
from mason.dbo.wms_SKU s(nolock)
where s.STORERKEY = 'KET'
and (ISNULL(s.newallocationstrategy, '') <> 'N01'
 or ISNULL(s.strategykey, '') = 'STD')

-- serialkey 114834 for hold status and one for non hold 121869 or 118828


-- ticket ATP-12693 kenra file feeds - info KR0000013081, contained items that NDS were not able to fulfill - SKU 41072, 41146. 
--
-- o id 36653261 c ref 556627296327 
select top 200 *
from mason.dbo.orders (nolock)
where reference_4 = 'WESTCOAST'
order by add_date desc
select *
from mason.dbo.orders (nolock)
where primary_reference = 'KR0000013103'
select *
from mason.dbo.ordersedit (nolock)
where primary_reference = 'KR0000013081'

select *
from mason.dbo.Lineitem (nolock)
where orders_id ='36653261'

select *
from Fulfillment_Transaction (nolock)
where trans_key01 = '36649453'
and trans_module = 'ORDERS'
and trans_submodule = 'shipped'
-- get from knr shopify get shipped orders (update)
SELECT DISTINCT
	o.orders_id				AS 'orders_id',
	o.primary_reference		AS 'primary_reference', 
	o.customer_reference	AS 'customer_orders_id',
	lf.flexfield21			AS 'customer_fulfillment_id',
	[dbo].[fGetTrackingNumbersForOrder] (
		o.primary_reference, ','
	)						AS 'tracking_numbers',
	ft.trans_id				AS 'trans_id'
FROM
	orders o with (nolock)
	INNER JOIN orders_flexfields ff with (nolock)
		ON ff.orders_id = o.orders_id
	INNER JOIN lineitem l with (nolock)
		ON l.orders_id = o.orders_id
	INNER JOIN lineitem_flexfields lf with (nolock)
		ON lf.lineitem_id = l.lineitem_id
	INNER JOIN fulfillment_transaction ft with (nolock)
		ON o.orders_id = ft.trans_key01
WHERE o.fulfillment_id = 1119
	AND o.order_status = 'SHIPPED'
	AND o.order_source = 'API'
	AND ff.flexfield30 = 'SHOPIFY'
	AND l.qty_shipped > 0
	AND l.qty_open = 0
	AND ISNULL(lf.flexfield21, '') != ''
	AND ft.trans_module = 'ORDERS' 
	AND ft.trans_submodule = 'SHIPPED'
	--AND ISNULL(ft.trans_status, '0') = '0'
	AND RIGHT(o.customer_reference, 10) > '5804104659'
	and o.primary_reference = 'KR0000013081'

	-- looked at this view View [dbo].[KNR_OrderExportToNDS]  input prim ref and helped identify vendor status and led to stor proc
	-- trigger sets in proc to set vendor status to pending for new order that is backordered from NDS in pr_Reserve_Orders

	-- CI-197 ZEVO fulfillment setup ticket
	/* where is step one? first step shows to copy an existing fulfillment then jumps to adding skus. would like to see how to create a new fulfillment either by A) copy existing
	or B) from scratch: where everything would be detailed to a tee.

	Create new fulfillment
		step 1 blank
		step 2 blank

	Or copy from existing fulfillment to create new fulfillment
		unique name for zevo 2 letter and 3 letters ZO ZVO

		look in s drive for script to help copy
		note if you dont have s drive access you need to use \\aeroshare03 
		then go to departments then IT development documentation

		new ffid for zv will be 1166

		follow directions in doc from cory
		edits
		when using doc to copy fulfillment setup - after step 2 update what do i do?
		do i run begin tran? do i run begin tran all the way to end? usually for exec proc
		i only have that store proc selected not the values to pass in after it.
		need way more notes in this proc.

needed to query zevo select and inserts with all fields having values for not nulls otherwise
i keep getting string or binary will be truncated error.
also after adding proper values i needed to add the same to insert below the create storer 
records inserts.

following errors occurred when trying to run this proc in AFSSQL due to me running this 
in prod last week and triggering a bunch of ancillary store procs creating data in tables

including but not limited to pk_contraints on dbo.WOWparameters table
and IX_Groups from dbo.Groups of proc pr_Groups_Insert. also dbo.Sequence 
and customer_fulfillment

go in and delete fulfillment id 1166 records for these tables. 
also occurred for customer_fulfillment in enterprise
here is the hell of a proc needed to set up a fulfillment

---- Run this select statement in Prod and UAT to determine what the new fulfillment_id should be.
--select max(fulfillment_id) + 1 from enterprise.dbo.Fulfillment (nolock)

/*				this section does not need to be used. skip and work with rest of query

---- If the max(fulfillment_id) is the same in UAT and Prod use this query to set the sequence to the max(fulfillment_id)
--Update enterprise.dbo.sequence set sequence = (select max(fulfillment_id) from ENTERPRISE.dbo.Fulfillment (nolock)) where seq_name = 'fulfillment'

--select * from fulfillment where order_prefix = 'ZC' 
----update fulfillment set order_prefix = 'ZC' where fulfillment_id = 259
--select * from fulfillment where short_name = 'cot'
--select * from fulfillment

--BEGIN TRAN


--delete from Sequence where seq_name = 'zo'
*/
-------------------------------
--	Navigator Setup
-------------------------------

Declare @today datetime = getdate(),
	@fulfillment_id int = 1166, 
	@copy_from_fulfillment int = 901,
	@copy_from_short_name varchar(5) = 'TLE',
	@parent_fulfillment_id int = 1,
	@short_name varchar(10) = 'ZVO',	 -- select * from fulfillment order by short_name
	@long_name varchar(200) = 'Zevo',
	@order_prefix varchar(2) = 'ZO',	 -- select * from fulfillment order by order_prefix
	@whse varchar(3) = 'WH1',
	@bill_storage varchar(50) = 'SQUARE FEET',
	@bill_order varchar(50) = 'STANDARD',
	@api varchar(10) = 'No' -- acceptable values are 'Yes' and 'No' -- Note: we should only be using the C# SmartConnect API so that is what is set up here.

EXECUTE Enterprise.dbo.pr_Fulfillment_Insert @fulfillment_id, @parent_fulfillment_id, @short_name, @long_name, @order_prefix, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@today,NULL,@whse, NULL,368, NULL,NULL,NULL,NULL,NULL,@bill_storage, @bill_order,NULL,NULL,NULL,NULL,NULL,NULL

update fulfillment set qc_percent = '100', bill_freight = 1 where fulfillment_id = @fulfillment_id

/* 					IMPORTANT!!!	IMPORTANT!!!	IMPORTANT!!!
 					IMPORTANT!!!	IMPORTANT!!!	IMPORTANT!!!
	 					IMPORTANT!!!	IMPORTANT!!!	IMPORTANT!!!
						 open this proc below and run it after main script runs
					lebanon.dbo.pr_Fulfillment_Copy_Wizard_Local	 
*/						 				 
--If @whse = 'WH1' 
--Begin
--	EXECUTE lebanon.dbo.pr_Fulfillment_Copy_Wizard_Local @copy_from_fulfillment, @fulfillment_id , 1
--End
--Else
--Begin
--	EXECUTE mason.dbo.pr_Fulfillment_Copy_Wizard_Local @copy_from_fulfillment, @fulfillment_id , 1
--End


--------------------------
-- WMS Setup
--------------------------

Declare
	@WAREHOUSE varchar(20),
	@DefaultReturnsLOC nvarchar(10)

If @whse = 'WH1' 
Begin
	set @DefaultReturnsLOC = 'RETURNS' --If whse1 then RETURNS, If whse2 the RETURN
	set	@WAREHOUSE = 'SCPRD_wmwhse1'
End
Else
Begin
	set @DefaultReturnsLOC = 'RETURN' --If whse1 then RETURNS, If whse2 the RETURN
	set	@WAREHOUSE = 'SCPRD_wmwhse2'
End

select @short_name,@long_name,@copy_from_short_name

SELECT [WHSEID],[STORERKEY] = @short_name,[TYPE],[SOURCEVERSION],[COMPANY] = @long_name,[VAT],[ADDRESS1],[ADDRESS2],[ADDRESS3],[ADDRESS4],[CITY],[STATE],[ZIP],[COUNTRY],[ISOCNTRYCODE],[CONTACT1],[CONTACT2],[PHONE1],[PHONE2],[FAX1],[FAX2],[EMAIL1],[EMAIL2],[B_CONTACT1],[B_CONTACT2],[B_COMPANY],[B_ADDRESS1],[B_ADDRESS2],[B_ADDRESS3],[B_ADDRESS4],[B_CITY],[B_STATE],[B_ZIP],[B_COUNTRY],[B_ISOCNTRYCODE],[B_PHONE1],[B_PHONE2],[B_FAX1],[B_FAX2],[B_EMAIL1],[B_EMAIL2],[CREDITLIMIT],[CARTONGROUP] = 'STD',[PICKCODE],[CREATEPATASKONRFRECEIPT],[CALCULATEPUTAWAYLOCATION],[STATUS],[DEFAULTSTRATEGY],[DEFAULTSKUROTATION],[DEFAULTROTATION],[SCAC_CODE],[TITLE1],[TITLE2],[DESCRIPTION],[SUSR1],[SUSR2],[SUSR3],[SUSR4],[SUSR5],[SUSR6],[MULTIZONEPLPA],[CWOFLAG],[ROLLRECEIPT],[NOTES1],[NOTES2],[APPORTIONRULE],[ENABLEOPPXDOCK],[ALLOWOVERSHIPMENT],[MAXIMUMORDERS],[MINIMUMPERCENT],[ORDERDATESTARTDAYS],[ORDERDATEENDDAYS],[ORDERTYPERESTRICT01],[ORDERTYPERESTRICT02],[ORDERTYPERESTRICT03],[ORDERTYPERESTRICT04],[ORDERTYPERESTRICT05],[ORDERTYPERESTRICT06],[OPPORDERSTRATEGYKEY],[RECEIPTVALIDATIONTEMPLATE],[ALLOWAUTOCLOSEFORPO],[ALLOWAUTOCLOSEFORASN],[ALLOWAUTOCLOSEFORPS],[ALLOWSYSTEMGENERATEDLPN],[ALLOWDUPLICATELICENSEPLATES],[ALLOWCOMMINGLEDLPN],[LPNBARCODESYMBOLOGY],[LPNBARCODEFORMAT],[ALLOWSINGLESCANRECEIVING],[LPNLENGTH],[APPLICATIONID],[SSCC1STDIGIT],[UCCVENDORNUMBER],[CASELABELTYPE],[AUTOPRINTLABELLPN],[AUTOPRINTLABELPUTAWAY],[LPNSTARTNUMBER],[NEXTLPNNUMBER],[LPNROLLBACKNUMBER],[BARCODECONFIGKEY],[DEFAULTPUTAWAYSTRATEGY],[AUTOCLOSEASN],[AUTOCLOSEPO],[TRACKINVENTORYBY],[DUPCASEID],[DEFAULTRETURNSLOC]= @DefaultReturnsLOC,[DEFAULTQCLOC],[PISKUXLOC],[CCSKUXLOC],[CCDISCREPANCYRULE],[CCADJBYRF],[ORDERBREAKDEFAULT],[SKUSETUPREQUIRED],[DEFAULTQCLOCOUT],[ENABLEPACKINGDEFAULT],[DEFAULTPACKINGLOCATION],[GENERATEPACKLIST],[PACKINGVALIDATIONTEMPLATE],[INSPECTATPACK],[ADDRESSOVERWRITEINDICATOR],[ACCOUNTINGENTITY],[CREATEOPPXDTASKS],[ISSUEOPPXDTASKS],[OPPXDPICKFROM],[OBXDSTAGE],[KSHIP_CARRIER],[SPSUOMWEIGHT],[SPSUOMDIMENSION],[DEFDAPICKSORT],[DEFRPLNSORT],[REQREASONSHORTSHIP],[EXPLODELPNLENGTH],[EXPLODELPNROLLBACKNUMBER],[EXPLODELPNSTARTNUMBER],[EXPLODENEXTLPNNUMBER],[OWNERPREFIX],[CONTAINEREXCHANGEFLAG],[CARTONIZEFTDFLT],[DEFFTLABELPRINT],[DEFFTTASKCONTROL],[MEASURECODE],[WGTUOM],[DIMENUOM],[CUBEUOM],[CURRCODE],[TAXGROUP],[DEFCORPCODE],[SURCHGBASETEMP],[AMBTEMPERATURE],[INVOICETERMS],[ARCORP],[ARDEPT],[ARACCT],[INVOICELEVEL],[NONNEGLEVEL],[TAXID],[DUNSID],[RECURCODE],[QFSURCHARGE],[BFSURCHARGE],[TAXEXEMPT],[TAXEXEMPTCODE],[TIMEZONE],[PLANDAYS],[ARCHIVEPLANNINGDAYS],[ARCHIVEREPORTINGDATA],[PLANENABLED],[DEFAULTHOURLYRATE],[DISTCALCMETHOD],[MAXCORNERANGLE],[SAVESTANDARDSAUDIT],[ADDRESS5],[ADDRESS6],[PARENT],[SPSACCOUNTNUM],[SPSCOSTCENTER],[SPSRETURNLABEL],[AMSTRATEGYKEY],[TEMPFORASN],[MIXEDLPNPUTSTRATEGY],[GROUPFTEACHDFLT],[ALLOCATEFTONCLOSE],[SPS_SCAC],[SPSAPISTRATEGYKEY],[PRINTPACKLIST],[PRINTPACKTEMPLATE],[PRINTCONTENTSREPORT],[PKTRACKINGID],[AUTOPRINTADDRESSLABEL],[AUTOPRINTORDERLABELS],[LOCALE],[PAYROLLPERIOD],[INITIALPAYROLLPERIODENDDATE],[PAYROLLEXTRACTFOLDER],[INCREMENTALEXTRACT],[DAYBOUNDARYMINUTES],[AUTOMATICFIRSTACTIVITY],[VENDORCOMPLYSTRATEGYKEY],[BACKORDER],[BOTYPE],[DEFAULTTRANSPORTATIONSERVICE],[DEFAULTEQUIPMENTATTRIBUTE],[DEFAULTEQUIPMENTTYPE],[DEFAULTEQUIPMENTLENGTH],[MIXPALLETPUTAWAYMETHOD],[DFLTEQUIPMENTFORASSGN],[DFLTEQUIPMENTFORPALLET],[RFAUTOFILLRCVLPN],[INBOUNDLPNLENGTH],[INBOUNDLPNPREFIX],[RFRCVAUTOPRINTLPN],[RECEIPTUNITLABELNAME],[RECEIPTUNITLABELUOM],[LASTSHIPPEDLOTCTRL],[ALLOCATIONLOTLIMIT],[OUTLABELSREQUIREDTOSHIP],[OUTLABELSREQUIREDTOBOL],[OUTBOUNDLABELSLEVEL],[OUTBOUNDLABELSCOUNTLEVEL],[STANDARDOUTBOUNDLABELPREFIX],[USEPARTNERLPNCONTROL],[EXTERNSTORERKEY],[AUTOFINALIZEPRODORDER],[CREATEMOVESFROMPROD],[PRODCOUNTLOC],[DEFAULTNEWALLOCATIONSTRATEGY],[MINSHELFLIFEOVERRIDEPCT]
	FROM [scprd].[wmwhse2].[STORER] WHERE type='1' AND STORERKEY = @copy_from_short_name 

SELECT [WHSEID],@short_name,[TYPE],[SOURCEVERSION],@long_name,[VAT],[ADDRESS1],[ADDRESS2],[ADDRESS3],[ADDRESS4],[CITY],[STATE],[ZIP],[COUNTRY],[ISOCNTRYCODE],[CONTACT1],[CONTACT2],[PHONE1],[PHONE2],[FAX1],[FAX2],[EMAIL1],[EMAIL2],[B_CONTACT1],[B_CONTACT2],[B_COMPANY],[B_ADDRESS1],[B_ADDRESS2],[B_ADDRESS3],[B_ADDRESS4],[B_CITY],[B_STATE],[B_ZIP],[B_COUNTRY],[B_ISOCNTRYCODE],[B_PHONE1],[B_PHONE2],[B_FAX1],[B_FAX2],[B_EMAIL1],[B_EMAIL2],[CREDITLIMIT],[CARTONGROUP] = 'STD',[PICKCODE],[CREATEPATASKONRFRECEIPT],[CALCULATEPUTAWAYLOCATION],[STATUS],[DEFAULTSTRATEGY],[DEFAULTSKUROTATION],[DEFAULTROTATION],[SCAC_CODE],[TITLE1],[TITLE2],[DESCRIPTION],[SUSR1],[SUSR2],[SUSR3],[SUSR4],[SUSR5],[SUSR6],[MULTIZONEPLPA],[CWOFLAG],[ROLLRECEIPT],[NOTES1],[NOTES2],[APPORTIONRULE],[ENABLEOPPXDOCK],[ALLOWOVERSHIPMENT],[MAXIMUMORDERS],[MINIMUMPERCENT],[ORDERDATESTARTDAYS],[ORDERDATEENDDAYS],[ORDERTYPERESTRICT01],[ORDERTYPERESTRICT02],[ORDERTYPERESTRICT03],[ORDERTYPERESTRICT04],[ORDERTYPERESTRICT05],[ORDERTYPERESTRICT06],[OPPORDERSTRATEGYKEY],[RECEIPTVALIDATIONTEMPLATE],[ALLOWAUTOCLOSEFORPO],[ALLOWAUTOCLOSEFORASN],[ALLOWAUTOCLOSEFORPS],[ALLOWSYSTEMGENERATEDLPN],[ALLOWDUPLICATELICENSEPLATES],[ALLOWCOMMINGLEDLPN],[LPNBARCODESYMBOLOGY],[LPNBARCODEFORMAT],[ALLOWSINGLESCANRECEIVING],[LPNLENGTH],[APPLICATIONID],[SSCC1STDIGIT],[UCCVENDORNUMBER],[CASELABELTYPE],[AUTOPRINTLABELLPN],[AUTOPRINTLABELPUTAWAY],[LPNSTARTNUMBER],[NEXTLPNNUMBER],[LPNROLLBACKNUMBER],[BARCODECONFIGKEY],[DEFAULTPUTAWAYSTRATEGY],[AUTOCLOSEASN],[AUTOCLOSEPO],[TRACKINVENTORYBY],[DUPCASEID],[DEFAULTRETURNSLOC]= 'RETURNS',[DEFAULTQCLOC],[PISKUXLOC],[CCSKUXLOC],[CCDISCREPANCYRULE],[CCADJBYRF],[ORDERBREAKDEFAULT],[SKUSETUPREQUIRED],[DEFAULTQCLOCOUT],[ENABLEPACKINGDEFAULT],[DEFAULTPACKINGLOCATION],[GENERATEPACKLIST],[PACKINGVALIDATIONTEMPLATE],[INSPECTATPACK],[ADDRESSOVERWRITEINDICATOR],[ACCOUNTINGENTITY],[CREATEOPPXDTASKS],[ISSUEOPPXDTASKS],[OPPXDPICKFROM],[OBXDSTAGE],[KSHIP_CARRIER],[SPSUOMWEIGHT],[SPSUOMDIMENSION],[DEFDAPICKSORT],[DEFRPLNSORT],[REQREASONSHORTSHIP],[EXPLODELPNLENGTH],[EXPLODELPNROLLBACKNUMBER],[EXPLODELPNSTARTNUMBER],[EXPLODENEXTLPNNUMBER],[OWNERPREFIX],[CONTAINEREXCHANGEFLAG],[CARTONIZEFTDFLT],[DEFFTLABELPRINT],[DEFFTTASKCONTROL],[MEASURECODE],[WGTUOM],[DIMENUOM],[CUBEUOM],[CURRCODE],[TAXGROUP],[DEFCORPCODE],[SURCHGBASETEMP],[AMBTEMPERATURE],[INVOICETERMS],[ARCORP],[ARDEPT],[ARACCT],[INVOICELEVEL],[NONNEGLEVEL],[TAXID],[DUNSID],[RECURCODE],[QFSURCHARGE],[BFSURCHARGE],[TAXEXEMPT],[TAXEXEMPTCODE],[TIMEZONE],[PLANDAYS],[ARCHIVEPLANNINGDAYS],[ARCHIVEREPORTINGDATA],[PLANENABLED],[DEFAULTHOURLYRATE],[DISTCALCMETHOD],[MAXCORNERANGLE],[SAVESTANDARDSAUDIT],[ADDRESS5],[ADDRESS6],[PARENT],[SPSACCOUNTNUM],[SPSCOSTCENTER],[SPSRETURNLABEL],[AMSTRATEGYKEY],[TEMPFORASN],[MIXEDLPNPUTSTRATEGY],[GROUPFTEACHDFLT],[ALLOCATEFTONCLOSE],[SPS_SCAC],[SPSAPISTRATEGYKEY],[PRINTPACKLIST],[PRINTPACKTEMPLATE],[PRINTCONTENTSREPORT],[PKTRACKINGID],[AUTOPRINTADDRESSLABEL],[AUTOPRINTORDERLABELS],[LOCALE],[PAYROLLPERIOD],[INITIALPAYROLLPERIODENDDATE],[PAYROLLEXTRACTFOLDER],[INCREMENTALEXTRACT],[DAYBOUNDARYMINUTES],[AUTOMATICFIRSTACTIVITY],[VENDORCOMPLYSTRATEGYKEY],[BACKORDER],[BOTYPE],[DEFAULTTRANSPORTATIONSERVICE],[DEFAULTEQUIPMENTATTRIBUTE],[DEFAULTEQUIPMENTTYPE],[DEFAULTEQUIPMENTLENGTH],[MIXPALLETPUTAWAYMETHOD],[DFLTEQUIPMENTFORASSGN],[DFLTEQUIPMENTFORPALLET],[RFAUTOFILLRCVLPN],[INBOUNDLPNLENGTH],[INBOUNDLPNPREFIX],[RFRCVAUTOPRINTLPN],[RECEIPTUNITLABELNAME],[RECEIPTUNITLABELUOM],[LASTSHIPPEDLOTCTRL],[ALLOCATIONLOTLIMIT],[OUTLABELSREQUIREDTOSHIP],[OUTLABELSREQUIREDTOBOL],[OUTBOUNDLABELSLEVEL],[OUTBOUNDLABELSCOUNTLEVEL],[STANDARDOUTBOUNDLABELPREFIX],[USEPARTNERLPNCONTROL],[EXTERNSTORERKEY],[AUTOFINALIZEPRODORDER],[CREATEMOVESFROMPROD],[PRODCOUNTLOC],[DEFAULTNEWALLOCATIONSTRATEGY],[MINSHELFLIFEOVERRIDEPCT]
	FROM [scprd].[wmwhse2].[STORER] WHERE type='1' AND [STORERKEY] = 'TLE' 


--Create Storer records
--Create Storer records
INSERT INTO [SCPRD].[enterprise].[STORER] ([WHSEID],[STORERKEY],[TYPE],[SOURCEVERSION],[COMPANY],[VAT],[ADDRESS1],[ADDRESS2],[ADDRESS3],[ADDRESS4],[CITY],[STATE],[ZIP],[COUNTRY],[ISOCNTRYCODE],[CONTACT1],[CONTACT2],[PHONE1],[PHONE2],[FAX1],[FAX2],[EMAIL1],[EMAIL2],[B_CONTACT1],[B_CONTACT2],[B_COMPANY],[B_ADDRESS1],[B_ADDRESS2],[B_ADDRESS3],[B_ADDRESS4],[B_CITY],[B_STATE],[B_ZIP],[B_COUNTRY],[B_ISOCNTRYCODE],[B_PHONE1],[B_PHONE2],[B_FAX1],[B_FAX2],[B_EMAIL1],[B_EMAIL2],[CREDITLIMIT],[CARTONGROUP],[PICKCODE],[CREATEPATASKONRFRECEIPT],[CALCULATEPUTAWAYLOCATION],[STATUS],[DEFAULTSTRATEGY],[DEFAULTSKUROTATION],[DEFAULTROTATION],[SCAC_CODE],[TITLE1],[TITLE2],[DESCRIPTION],[SUSR1],[SUSR2],[SUSR3],[SUSR4],[SUSR5],[SUSR6],[MULTIZONEPLPA],[CWOFLAG],[ROLLRECEIPT],[NOTES1],[NOTES2],[APPORTIONRULE],[ENABLEOPPXDOCK],[ALLOWOVERSHIPMENT],[MAXIMUMORDERS],[MINIMUMPERCENT],[ORDERDATESTARTDAYS],[ORDERDATEENDDAYS],[ORDERTYPERESTRICT01],[ORDERTYPERESTRICT02],[ORDERTYPERESTRICT03],[ORDERTYPERESTRICT04],[ORDERTYPERESTRICT05],[ORDERTYPERESTRICT06],[OPPORDERSTRATEGYKEY],[RECEIPTVALIDATIONTEMPLATE],[ALLOWAUTOCLOSEFORPO],[ALLOWAUTOCLOSEFORASN],[ALLOWAUTOCLOSEFORPS],[ALLOWSYSTEMGENERATEDLPN],[ALLOWDUPLICATELICENSEPLATES],[ALLOWCOMMINGLEDLPN],[LPNBARCODESYMBOLOGY],[LPNBARCODEFORMAT],[ALLOWSINGLESCANRECEIVING],[LPNLENGTH],[APPLICATIONID],[SSCC1STDIGIT],[UCCVENDORNUMBER],[CASELABELTYPE],[AUTOPRINTLABELLPN],[AUTOPRINTLABELPUTAWAY],[LPNSTARTNUMBER],[NEXTLPNNUMBER],[LPNROLLBACKNUMBER],[BARCODECONFIGKEY],[DEFAULTPUTAWAYSTRATEGY],[AUTOCLOSEASN],[AUTOCLOSEPO],[TRACKINVENTORYBY],[DUPCASEID],[DEFAULTRETURNSLOC],[DEFAULTQCLOC],[PISKUXLOC],[CCSKUXLOC],[CCDISCREPANCYRULE],[CCADJBYRF],[ORDERBREAKDEFAULT],[SKUSETUPREQUIRED],[DEFAULTQCLOCOUT],[ENABLEPACKINGDEFAULT],[DEFAULTPACKINGLOCATION],[GENERATEPACKLIST],[PACKINGVALIDATIONTEMPLATE],[INSPECTATPACK],[ADDRESSOVERWRITEINDICATOR],[ACCOUNTINGENTITY],[CREATEOPPXDTASKS],[ISSUEOPPXDTASKS],[OPPXDPICKFROM],[OBXDSTAGE],[KSHIP_CARRIER],[SPSUOMWEIGHT],[SPSUOMDIMENSION],[DEFDAPICKSORT],[DEFRPLNSORT],[REQREASONSHORTSHIP],[EXPLODELPNLENGTH],[EXPLODELPNROLLBACKNUMBER],[EXPLODELPNSTARTNUMBER],	[EXPLODENEXTLPNNUMBER],[OWNERPREFIX],[CONTAINEREXCHANGEFLAG],[CARTONIZEFTDFLT],[DEFFTLABELPRINT],[DEFFTTASKCONTROL],[MEASURECODE],[WGTUOM],[DIMENUOM],[CUBEUOM],[CURRCODE],[TAXGROUP],[DEFCORPCODE],[SURCHGBASETEMP],[AMBTEMPERATURE],	[INVOICETERMS],[ARCORP],[ARDEPT],[ARACCT],[INVOICELEVEL],[NONNEGLEVEL],[TAXID],[DUNSID],[RECURCODE],[QFSURCHARGE],[BFSURCHARGE],[TAXEXEMPT],[TAXEXEMPTCODE],[TIMEZONE],[PLANDAYS],[ARCHIVEPLANNINGDAYS],[ARCHIVEREPORTINGDATA],	[PLANENABLED],[DEFAULTHOURLYRATE],[DISTCALCMETHOD],[MAXCORNERANGLE],[SAVESTANDARDSAUDIT],[ADDRESS5],[ADDRESS6],[PARENT],[SPSACCOUNTNUM],[SPSCOSTCENTER],[SPSRETURNLABEL],[AMSTRATEGYKEY],[TEMPFORASN],[MIXEDLPNPUTSTRATEGY],	[GROUPFTEACHDFLT],[ALLOCATEFTONCLOSE],[SPS_SCAC],[SPSAPISTRATEGYKEY],[PRINTPACKLIST],[PRINTPACKTEMPLATE],[PRINTCONTENTSREPORT],[PKTRACKINGID],[AUTOPRINTADDRESSLABEL],[AUTOPRINTORDERLABELS],[LOCALE],[PAYROLLPERIOD],	[INITIALPAYROLLPERIODENDDATE],[PAYROLLEXTRACTFOLDER],[INCREMENTALEXTRACT],[DAYBOUNDARYMINUTES],[AUTOMATICFIRSTACTIVITY],[VENDORCOMPLYSTRATEGYKEY],[BACKORDER],[BOTYPE],[DEFAULTTRANSPORTATIONSERVICE],[DEFAULTEQUIPMENTATTRIBUTE],	[DEFAULTEQUIPMENTTYPE],[DEFAULTEQUIPMENTLENGTH],[MIXPALLETPUTAWAYMETHOD],[DFLTEQUIPMENTFORASSGN],[DFLTEQUIPMENTFORPALLET],[RFAUTOFILLRCVLPN],[INBOUNDLPNLENGTH],[INBOUNDLPNPREFIX],[RFRCVAUTOPRINTLPN],[RECEIPTUNITLABELNAME],[RECEIPTUNITLABELUOM],	[LASTSHIPPEDLOTCTRL],[ALLOCATIONLOTLIMIT],[OUTLABELSREQUIREDTOSHIP],[OUTLABELSREQUIREDTOBOL],[OUTBOUNDLABELSLEVEL],[OUTBOUNDLABELSCOUNTLEVEL],[STANDARDOUTBOUNDLABELPREFIX],[USEPARTNERLPNCONTROL],[EXTERNSTORERKEY],[AUTOFINALIZEPRODORDER],	[CREATEMOVESFROMPROD],[PRODCOUNTLOC],[DEFAULTNEWALLOCATIONSTRATEGY],[MINSHELFLIFEOVERRIDEPCT],[adddate],addwho,editdate,editwho)	
	SELECT [WHSEID],@short_name,[TYPE],[SOURCEVERSION],@long_name,[VAT],[ADDRESS1],[ADDRESS2],[ADDRESS3],[ADDRESS4],[CITY],[STATE],[ZIP],[COUNTRY],[ISOCNTRYCODE],[CONTACT1],[CONTACT2],[PHONE1],[PHONE2],[FAX1],[FAX2],[EMAIL1],[EMAIL2],[B_CONTACT1],[B_CONTACT2],[B_COMPANY],[B_ADDRESS1],[B_ADDRESS2],[B_ADDRESS3],[B_ADDRESS4],[B_CITY],[B_STATE],[B_ZIP],[B_COUNTRY],[B_ISOCNTRYCODE],[B_PHONE1],[B_PHONE2],[B_FAX1],[B_FAX2],[B_EMAIL1],[B_EMAIL2],[CREDITLIMIT],[CARTONGROUP] = 'STD',[PICKCODE],[CREATEPATASKONRFRECEIPT],[CALCULATEPUTAWAYLOCATION],[STATUS],[DEFAULTSTRATEGY],[DEFAULTSKUROTATION],[DEFAULTROTATION],[SCAC_CODE],[TITLE1],[TITLE2],[DESCRIPTION],[SUSR1],[SUSR2],[SUSR3],[SUSR4],[SUSR5],[SUSR6],[MULTIZONEPLPA],[CWOFLAG],[ROLLRECEIPT],[NOTES1],[NOTES2],[APPORTIONRULE],[ENABLEOPPXDOCK],[ALLOWOVERSHIPMENT],[MAXIMUMORDERS],[MINIMUMPERCENT],[ORDERDATESTARTDAYS],[ORDERDATEENDDAYS],[ORDERTYPERESTRICT01],[ORDERTYPERESTRICT02],[ORDERTYPERESTRICT03],[ORDERTYPERESTRICT04],[ORDERTYPERESTRICT05],[ORDERTYPERESTRICT06],[OPPORDERSTRATEGYKEY],[RECEIPTVALIDATIONTEMPLATE],[ALLOWAUTOCLOSEFORPO],[ALLOWAUTOCLOSEFORASN],[ALLOWAUTOCLOSEFORPS],[ALLOWSYSTEMGENERATEDLPN],[ALLOWDUPLICATELICENSEPLATES],[ALLOWCOMMINGLEDLPN],[LPNBARCODESYMBOLOGY],[LPNBARCODEFORMAT],[ALLOWSINGLESCANRECEIVING],[LPNLENGTH],[APPLICATIONID],[SSCC1STDIGIT],[UCCVENDORNUMBER],[CASELABELTYPE],[AUTOPRINTLABELLPN],[AUTOPRINTLABELPUTAWAY],[LPNSTARTNUMBER],[NEXTLPNNUMBER],[LPNROLLBACKNUMBER],[BARCODECONFIGKEY],[DEFAULTPUTAWAYSTRATEGY],[AUTOCLOSEASN],[AUTOCLOSEPO],[TRACKINVENTORYBY],[DUPCASEID],[DEFAULTRETURNSLOC]= 'RETURNS',[DEFAULTQCLOC],[PISKUXLOC],[CCSKUXLOC],[CCDISCREPANCYRULE],[CCADJBYRF],[ORDERBREAKDEFAULT],[SKUSETUPREQUIRED],[DEFAULTQCLOCOUT],[ENABLEPACKINGDEFAULT],[DEFAULTPACKINGLOCATION],[GENERATEPACKLIST],[PACKINGVALIDATIONTEMPLATE],[INSPECTATPACK],[ADDRESSOVERWRITEINDICATOR],[ACCOUNTINGENTITY],[CREATEOPPXDTASKS],[ISSUEOPPXDTASKS],[OPPXDPICKFROM],[OBXDSTAGE],[KSHIP_CARRIER],[SPSUOMWEIGHT],[SPSUOMDIMENSION],[DEFDAPICKSORT],[DEFRPLNSORT],[REQREASONSHORTSHIP],[EXPLODELPNLENGTH],[EXPLODELPNROLLBACKNUMBER],[EXPLODELPNSTARTNUMBER],[EXPLODENEXTLPNNUMBER],[OWNERPREFIX],[CONTAINEREXCHANGEFLAG],[CARTONIZEFTDFLT],[DEFFTLABELPRINT],[DEFFTTASKCONTROL],[MEASURECODE],[WGTUOM],[DIMENUOM],[CUBEUOM],[CURRCODE],[TAXGROUP],[DEFCORPCODE],[SURCHGBASETEMP],[AMBTEMPERATURE],[INVOICETERMS],[ARCORP],[ARDEPT],[ARACCT],[INVOICELEVEL],[NONNEGLEVEL],[TAXID],[DUNSID],[RECURCODE],[QFSURCHARGE],[BFSURCHARGE],[TAXEXEMPT],[TAXEXEMPTCODE],[TIMEZONE],[PLANDAYS],[ARCHIVEPLANNINGDAYS],[ARCHIVEREPORTINGDATA],[PLANENABLED],[DEFAULTHOURLYRATE],[DISTCALCMETHOD],[MAXCORNERANGLE],[SAVESTANDARDSAUDIT],[ADDRESS5],[ADDRESS6],[PARENT],[SPSACCOUNTNUM],[SPSCOSTCENTER],[SPSRETURNLABEL],[AMSTRATEGYKEY],[TEMPFORASN],[MIXEDLPNPUTSTRATEGY],[GROUPFTEACHDFLT],[ALLOCATEFTONCLOSE],[SPS_SCAC],[SPSAPISTRATEGYKEY],[PRINTPACKLIST],[PRINTPACKTEMPLATE],[PRINTCONTENTSREPORT],[PKTRACKINGID],[AUTOPRINTADDRESSLABEL],[AUTOPRINTORDERLABELS],[LOCALE],[PAYROLLPERIOD],[INITIALPAYROLLPERIODENDDATE],[PAYROLLEXTRACTFOLDER],[INCREMENTALEXTRACT],[DAYBOUNDARYMINUTES],[AUTOMATICFIRSTACTIVITY],[VENDORCOMPLYSTRATEGYKEY],[BACKORDER],[BOTYPE],[DEFAULTTRANSPORTATIONSERVICE],[DEFAULTEQUIPMENTATTRIBUTE],[DEFAULTEQUIPMENTTYPE],[DEFAULTEQUIPMENTLENGTH],[MIXPALLETPUTAWAYMETHOD],[DFLTEQUIPMENTFORASSGN],[DFLTEQUIPMENTFORPALLET],[RFAUTOFILLRCVLPN],[INBOUNDLPNLENGTH],[INBOUNDLPNPREFIX],[RFRCVAUTOPRINTLPN],[RECEIPTUNITLABELNAME],[RECEIPTUNITLABELUOM],[LASTSHIPPEDLOTCTRL],[ALLOCATIONLOTLIMIT],[OUTLABELSREQUIREDTOSHIP],[OUTLABELSREQUIREDTOBOL],[OUTBOUNDLABELSLEVEL],[OUTBOUNDLABELSCOUNTLEVEL],[STANDARDOUTBOUNDLABELPREFIX],[USEPARTNERLPNCONTROL],[EXTERNSTORERKEY],[AUTOFINALIZEPRODORDER],[CREATEMOVESFROMPROD],[PRODCOUNTLOC],[DEFAULTNEWALLOCATIONSTRATEGY],[MINSHELFLIFEOVERRIDEPCT],getdate(),'ben',getdate(),'ben'
	FROM [scprd].[wmwhse2].[STORER] WHERE type='1' AND [STORERKEY] = 'TLE'

	--select top 2 * from [scprd].[wmwhse2].[STORER] where [STORERKEY] = 'CPG'

INSERT INTO [SCPRD].[wmwhse1].[STORER] ([WHSEID],[STORERKEY],[TYPE],[SOURCEVERSION],[COMPANY],[VAT],[ADDRESS1],[ADDRESS2],[ADDRESS3],[ADDRESS4],[CITY],[STATE],[ZIP],[COUNTRY],[ISOCNTRYCODE],[CONTACT1],[CONTACT2],[PHONE1],[PHONE2],[FAX1],[FAX2],[EMAIL1],[EMAIL2],[B_CONTACT1],[B_CONTACT2],[B_COMPANY],[B_ADDRESS1],[B_ADDRESS2],[B_ADDRESS3],[B_ADDRESS4],[B_CITY],[B_STATE],[B_ZIP],[B_COUNTRY],[B_ISOCNTRYCODE],[B_PHONE1],[B_PHONE2],[B_FAX1],[B_FAX2],[B_EMAIL1],[B_EMAIL2],[CREDITLIMIT],[CARTONGROUP],[PICKCODE],[CREATEPATASKONRFRECEIPT],[CALCULATEPUTAWAYLOCATION],[STATUS],[DEFAULTSTRATEGY],[DEFAULTSKUROTATION],[DEFAULTROTATION],[SCAC_CODE],[TITLE1],[TITLE2],[DESCRIPTION],[SUSR1],[SUSR2],[SUSR3],[SUSR4],[SUSR5],[SUSR6],[MULTIZONEPLPA],[CWOFLAG],[ROLLRECEIPT],[NOTES1],[NOTES2],[APPORTIONRULE],[ENABLEOPPXDOCK],[ALLOWOVERSHIPMENT],[MAXIMUMORDERS],[MINIMUMPERCENT],[ORDERDATESTARTDAYS],[ORDERDATEENDDAYS],[ORDERTYPERESTRICT01],[ORDERTYPERESTRICT02],[ORDERTYPERESTRICT03],[ORDERTYPERESTRICT04],[ORDERTYPERESTRICT05],[ORDERTYPERESTRICT06],[OPPORDERSTRATEGYKEY],[RECEIPTVALIDATIONTEMPLATE],[ALLOWAUTOCLOSEFORPO],[ALLOWAUTOCLOSEFORASN],[ALLOWAUTOCLOSEFORPS],[ALLOWSYSTEMGENERATEDLPN],[ALLOWDUPLICATELICENSEPLATES],[ALLOWCOMMINGLEDLPN],[LPNBARCODESYMBOLOGY],[LPNBARCODEFORMAT],[ALLOWSINGLESCANRECEIVING],[LPNLENGTH],[APPLICATIONID],[SSCC1STDIGIT],[UCCVENDORNUMBER],[CASELABELTYPE],[AUTOPRINTLABELLPN],[AUTOPRINTLABELPUTAWAY],[LPNSTARTNUMBER],[NEXTLPNNUMBER],[LPNROLLBACKNUMBER],[BARCODECONFIGKEY],[DEFAULTPUTAWAYSTRATEGY],[AUTOCLOSEASN],[AUTOCLOSEPO],[TRACKINVENTORYBY],[DUPCASEID],[DEFAULTRETURNSLOC],[DEFAULTQCLOC],[PISKUXLOC],[CCSKUXLOC],[CCDISCREPANCYRULE],[CCADJBYRF],[ORDERBREAKDEFAULT],[SKUSETUPREQUIRED],[DEFAULTQCLOCOUT],[ENABLEPACKINGDEFAULT],[DEFAULTPACKINGLOCATION],[GENERATEPACKLIST],[PACKINGVALIDATIONTEMPLATE],[INSPECTATPACK],[ADDRESSOVERWRITEINDICATOR],[ACCOUNTINGENTITY],[CREATEOPPXDTASKS],[ISSUEOPPXDTASKS],[OPPXDPICKFROM],[OBXDSTAGE],[KSHIP_CARRIER],[SPSUOMWEIGHT],[SPSUOMDIMENSION],[DEFDAPICKSORT],[DEFRPLNSORT],[REQREASONSHORTSHIP],[EXPLODELPNLENGTH],[EXPLODELPNROLLBACKNUMBER],[EXPLODELPNSTARTNUMBER],	[EXPLODENEXTLPNNUMBER],[OWNERPREFIX],[CONTAINEREXCHANGEFLAG],[CARTONIZEFTDFLT],[DEFFTLABELPRINT],[DEFFTTASKCONTROL],[MEASURECODE],[WGTUOM],[DIMENUOM],[CUBEUOM],[CURRCODE],[TAXGROUP],[DEFCORPCODE],[SURCHGBASETEMP],[AMBTEMPERATURE],	[INVOICETERMS],[ARCORP],[ARDEPT],[ARACCT],[INVOICELEVEL],[NONNEGLEVEL],[TAXID],[DUNSID],[RECURCODE],[QFSURCHARGE],[BFSURCHARGE],[TAXEXEMPT],[TAXEXEMPTCODE],[TIMEZONE],[PLANDAYS],[ARCHIVEPLANNINGDAYS],[ARCHIVEREPORTINGDATA],	[PLANENABLED],[DEFAULTHOURLYRATE],[DISTCALCMETHOD],[MAXCORNERANGLE],[SAVESTANDARDSAUDIT],[ADDRESS5],[ADDRESS6],[PARENT],[SPSACCOUNTNUM],[SPSCOSTCENTER],[SPSRETURNLABEL],[AMSTRATEGYKEY],[TEMPFORASN],[MIXEDLPNPUTSTRATEGY],	[GROUPFTEACHDFLT],[ALLOCATEFTONCLOSE],[SPS_SCAC],[SPSAPISTRATEGYKEY],[PRINTPACKLIST],[PRINTPACKTEMPLATE],[PRINTCONTENTSREPORT],[PKTRACKINGID],[AUTOPRINTADDRESSLABEL],[AUTOPRINTORDERLABELS],[LOCALE],[PAYROLLPERIOD],	[INITIALPAYROLLPERIODENDDATE],[PAYROLLEXTRACTFOLDER],[INCREMENTALEXTRACT],[DAYBOUNDARYMINUTES],[AUTOMATICFIRSTACTIVITY],[VENDORCOMPLYSTRATEGYKEY],[BACKORDER],[BOTYPE],[DEFAULTTRANSPORTATIONSERVICE],[DEFAULTEQUIPMENTATTRIBUTE],	[DEFAULTEQUIPMENTTYPE],[DEFAULTEQUIPMENTLENGTH],[MIXPALLETPUTAWAYMETHOD],[DFLTEQUIPMENTFORASSGN],[DFLTEQUIPMENTFORPALLET],[RFAUTOFILLRCVLPN],[INBOUNDLPNLENGTH],[INBOUNDLPNPREFIX],[RFRCVAUTOPRINTLPN],[RECEIPTUNITLABELNAME],[RECEIPTUNITLABELUOM],	[LASTSHIPPEDLOTCTRL],[ALLOCATIONLOTLIMIT],[OUTLABELSREQUIREDTOSHIP],[OUTLABELSREQUIREDTOBOL],[OUTBOUNDLABELSLEVEL],[OUTBOUNDLABELSCOUNTLEVEL],[STANDARDOUTBOUNDLABELPREFIX],[USEPARTNERLPNCONTROL],[EXTERNSTORERKEY],[AUTOFINALIZEPRODORDER],	[CREATEMOVESFROMPROD],[PRODCOUNTLOC],[DEFAULTNEWALLOCATIONSTRATEGY],[MINSHELFLIFEOVERRIDEPCT],[adddate],addwho,editdate,editwho)	
	SELECT [WHSEID],@short_name,[TYPE],[SOURCEVERSION],@long_name,[VAT],[ADDRESS1],[ADDRESS2],[ADDRESS3],[ADDRESS4],[CITY],[STATE],[ZIP],[COUNTRY],[ISOCNTRYCODE],[CONTACT1],[CONTACT2],[PHONE1],[PHONE2],[FAX1],[FAX2],[EMAIL1],[EMAIL2],[B_CONTACT1],[B_CONTACT2],[B_COMPANY],[B_ADDRESS1],[B_ADDRESS2],[B_ADDRESS3],[B_ADDRESS4],[B_CITY],[B_STATE],[B_ZIP],[B_COUNTRY],[B_ISOCNTRYCODE],[B_PHONE1],[B_PHONE2],[B_FAX1],[B_FAX2],[B_EMAIL1],[B_EMAIL2],[CREDITLIMIT],[CARTONGROUP] = 'STD',[PICKCODE],[CREATEPATASKONRFRECEIPT],[CALCULATEPUTAWAYLOCATION],[STATUS],[DEFAULTSTRATEGY],[DEFAULTSKUROTATION],[DEFAULTROTATION],[SCAC_CODE],[TITLE1],[TITLE2],[DESCRIPTION],[SUSR1],[SUSR2],[SUSR3],[SUSR4],[SUSR5],[SUSR6],[MULTIZONEPLPA],[CWOFLAG],[ROLLRECEIPT],[NOTES1],[NOTES2],[APPORTIONRULE],[ENABLEOPPXDOCK],[ALLOWOVERSHIPMENT],[MAXIMUMORDERS],[MINIMUMPERCENT],[ORDERDATESTARTDAYS],[ORDERDATEENDDAYS],[ORDERTYPERESTRICT01],[ORDERTYPERESTRICT02],[ORDERTYPERESTRICT03],[ORDERTYPERESTRICT04],[ORDERTYPERESTRICT05],[ORDERTYPERESTRICT06],[OPPORDERSTRATEGYKEY],[RECEIPTVALIDATIONTEMPLATE],[ALLOWAUTOCLOSEFORPO],[ALLOWAUTOCLOSEFORASN],[ALLOWAUTOCLOSEFORPS],[ALLOWSYSTEMGENERATEDLPN],[ALLOWDUPLICATELICENSEPLATES],[ALLOWCOMMINGLEDLPN],[LPNBARCODESYMBOLOGY],[LPNBARCODEFORMAT],[ALLOWSINGLESCANRECEIVING],[LPNLENGTH],[APPLICATIONID],[SSCC1STDIGIT],[UCCVENDORNUMBER],[CASELABELTYPE],[AUTOPRINTLABELLPN],[AUTOPRINTLABELPUTAWAY],[LPNSTARTNUMBER],[NEXTLPNNUMBER],[LPNROLLBACKNUMBER],[BARCODECONFIGKEY],[DEFAULTPUTAWAYSTRATEGY],[AUTOCLOSEASN],[AUTOCLOSEPO],[TRACKINVENTORYBY],[DUPCASEID],[DEFAULTRETURNSLOC]= 'RETURNS',[DEFAULTQCLOC],[PISKUXLOC],[CCSKUXLOC],[CCDISCREPANCYRULE],[CCADJBYRF],[ORDERBREAKDEFAULT],[SKUSETUPREQUIRED],[DEFAULTQCLOCOUT],[ENABLEPACKINGDEFAULT],[DEFAULTPACKINGLOCATION],[GENERATEPACKLIST],[PACKINGVALIDATIONTEMPLATE],[INSPECTATPACK],[ADDRESSOVERWRITEINDICATOR],[ACCOUNTINGENTITY],[CREATEOPPXDTASKS],[ISSUEOPPXDTASKS],[OPPXDPICKFROM],[OBXDSTAGE],[KSHIP_CARRIER],[SPSUOMWEIGHT],[SPSUOMDIMENSION],[DEFDAPICKSORT],[DEFRPLNSORT],[REQREASONSHORTSHIP],[EXPLODELPNLENGTH],[EXPLODELPNROLLBACKNUMBER],[EXPLODELPNSTARTNUMBER],[EXPLODENEXTLPNNUMBER],[OWNERPREFIX],[CONTAINEREXCHANGEFLAG],[CARTONIZEFTDFLT],[DEFFTLABELPRINT],[DEFFTTASKCONTROL],[MEASURECODE],[WGTUOM],[DIMENUOM],[CUBEUOM],[CURRCODE],[TAXGROUP],[DEFCORPCODE],[SURCHGBASETEMP],[AMBTEMPERATURE],[INVOICETERMS],[ARCORP],[ARDEPT],[ARACCT],[INVOICELEVEL],[NONNEGLEVEL],[TAXID],[DUNSID],[RECURCODE],[QFSURCHARGE],[BFSURCHARGE],[TAXEXEMPT],[TAXEXEMPTCODE],[TIMEZONE],[PLANDAYS],[ARCHIVEPLANNINGDAYS],[ARCHIVEREPORTINGDATA],[PLANENABLED],[DEFAULTHOURLYRATE],[DISTCALCMETHOD],[MAXCORNERANGLE],[SAVESTANDARDSAUDIT],[ADDRESS5],[ADDRESS6],[PARENT],[SPSACCOUNTNUM],[SPSCOSTCENTER],[SPSRETURNLABEL],[AMSTRATEGYKEY],[TEMPFORASN],[MIXEDLPNPUTSTRATEGY],[GROUPFTEACHDFLT],[ALLOCATEFTONCLOSE],[SPS_SCAC],[SPSAPISTRATEGYKEY],[PRINTPACKLIST],[PRINTPACKTEMPLATE],[PRINTCONTENTSREPORT],[PKTRACKINGID],[AUTOPRINTADDRESSLABEL],[AUTOPRINTORDERLABELS],[LOCALE],[PAYROLLPERIOD],[INITIALPAYROLLPERIODENDDATE],[PAYROLLEXTRACTFOLDER],[INCREMENTALEXTRACT],[DAYBOUNDARYMINUTES],[AUTOMATICFIRSTACTIVITY],[VENDORCOMPLYSTRATEGYKEY],[BACKORDER],[BOTYPE],[DEFAULTTRANSPORTATIONSERVICE],[DEFAULTEQUIPMENTATTRIBUTE],[DEFAULTEQUIPMENTTYPE],[DEFAULTEQUIPMENTLENGTH],[MIXPALLETPUTAWAYMETHOD],[DFLTEQUIPMENTFORASSGN],[DFLTEQUIPMENTFORPALLET],[RFAUTOFILLRCVLPN],[INBOUNDLPNLENGTH],[INBOUNDLPNPREFIX],[RFRCVAUTOPRINTLPN],[RECEIPTUNITLABELNAME],[RECEIPTUNITLABELUOM],[LASTSHIPPEDLOTCTRL],[ALLOCATIONLOTLIMIT],[OUTLABELSREQUIREDTOSHIP],[OUTLABELSREQUIREDTOBOL],[OUTBOUNDLABELSLEVEL],[OUTBOUNDLABELSCOUNTLEVEL],[STANDARDOUTBOUNDLABELPREFIX],[USEPARTNERLPNCONTROL],[EXTERNSTORERKEY],[AUTOFINALIZEPRODORDER],[CREATEMOVESFROMPROD],[PRODCOUNTLOC],[DEFAULTNEWALLOCATIONSTRATEGY],[MINSHELFLIFEOVERRIDEPCT],getdate(),'ben',getdate(),'ben'
	FROM [scprd].[wmwhse2].[STORER] WHERE type='1' AND [STORERKEY] = 'TLE'


INSERT INTO [SCPRD].[wmwhse2].[STORER] ([WHSEID],[STORERKEY],[TYPE],[SOURCEVERSION],[COMPANY],[VAT],[ADDRESS1],[ADDRESS2],[ADDRESS3],[ADDRESS4],[CITY],[STATE],[ZIP],[COUNTRY],[ISOCNTRYCODE],[CONTACT1],[CONTACT2],[PHONE1],[PHONE2],[FAX1],[FAX2],[EMAIL1],[EMAIL2],[B_CONTACT1],[B_CONTACT2],[B_COMPANY],[B_ADDRESS1],[B_ADDRESS2],[B_ADDRESS3],[B_ADDRESS4],[B_CITY],[B_STATE],[B_ZIP],[B_COUNTRY],[B_ISOCNTRYCODE],[B_PHONE1],[B_PHONE2],[B_FAX1],[B_FAX2],[B_EMAIL1],[B_EMAIL2],[CREDITLIMIT],[CARTONGROUP],[PICKCODE],[CREATEPATASKONRFRECEIPT],[CALCULATEPUTAWAYLOCATION],[STATUS],[DEFAULTSTRATEGY],[DEFAULTSKUROTATION],[DEFAULTROTATION],[SCAC_CODE],[TITLE1],[TITLE2],[DESCRIPTION],[SUSR1],[SUSR2],[SUSR3],[SUSR4],[SUSR5],[SUSR6],[MULTIZONEPLPA],[CWOFLAG],[ROLLRECEIPT],[NOTES1],[NOTES2],[APPORTIONRULE],[ENABLEOPPXDOCK],[ALLOWOVERSHIPMENT],[MAXIMUMORDERS],[MINIMUMPERCENT],[ORDERDATESTARTDAYS],[ORDERDATEENDDAYS],[ORDERTYPERESTRICT01],[ORDERTYPERESTRICT02],[ORDERTYPERESTRICT03],[ORDERTYPERESTRICT04],[ORDERTYPERESTRICT05],[ORDERTYPERESTRICT06],[OPPORDERSTRATEGYKEY],[RECEIPTVALIDATIONTEMPLATE],[ALLOWAUTOCLOSEFORPO],[ALLOWAUTOCLOSEFORASN],[ALLOWAUTOCLOSEFORPS],[ALLOWSYSTEMGENERATEDLPN],[ALLOWDUPLICATELICENSEPLATES],[ALLOWCOMMINGLEDLPN],[LPNBARCODESYMBOLOGY],[LPNBARCODEFORMAT],[ALLOWSINGLESCANRECEIVING],[LPNLENGTH],[APPLICATIONID],[SSCC1STDIGIT],[UCCVENDORNUMBER],[CASELABELTYPE],[AUTOPRINTLABELLPN],[AUTOPRINTLABELPUTAWAY],[LPNSTARTNUMBER],[NEXTLPNNUMBER],[LPNROLLBACKNUMBER],[BARCODECONFIGKEY],[DEFAULTPUTAWAYSTRATEGY],[AUTOCLOSEASN],[AUTOCLOSEPO],[TRACKINVENTORYBY],[DUPCASEID],[DEFAULTRETURNSLOC],[DEFAULTQCLOC],[PISKUXLOC],[CCSKUXLOC],[CCDISCREPANCYRULE],[CCADJBYRF],[ORDERBREAKDEFAULT],[SKUSETUPREQUIRED],[DEFAULTQCLOCOUT],[ENABLEPACKINGDEFAULT],[DEFAULTPACKINGLOCATION],[GENERATEPACKLIST],[PACKINGVALIDATIONTEMPLATE],[INSPECTATPACK],[ADDRESSOVERWRITEINDICATOR],[ACCOUNTINGENTITY],[CREATEOPPXDTASKS],[ISSUEOPPXDTASKS],[OPPXDPICKFROM],[OBXDSTAGE],[KSHIP_CARRIER],[SPSUOMWEIGHT],[SPSUOMDIMENSION],[DEFDAPICKSORT],[DEFRPLNSORT],[REQREASONSHORTSHIP],[EXPLODELPNLENGTH],[EXPLODELPNROLLBACKNUMBER],[EXPLODELPNSTARTNUMBER],	[EXPLODENEXTLPNNUMBER],[OWNERPREFIX],[CONTAINEREXCHANGEFLAG],[CARTONIZEFTDFLT],[DEFFTLABELPRINT],[DEFFTTASKCONTROL],[MEASURECODE],[WGTUOM],[DIMENUOM],[CUBEUOM],[CURRCODE],[TAXGROUP],[DEFCORPCODE],[SURCHGBASETEMP],[AMBTEMPERATURE],	[INVOICETERMS],[ARCORP],[ARDEPT],[ARACCT],[INVOICELEVEL],[NONNEGLEVEL],[TAXID],[DUNSID],[RECURCODE],[QFSURCHARGE],[BFSURCHARGE],[TAXEXEMPT],[TAXEXEMPTCODE],[TIMEZONE],[PLANDAYS],[ARCHIVEPLANNINGDAYS],[ARCHIVEREPORTINGDATA],	[PLANENABLED],[DEFAULTHOURLYRATE],[DISTCALCMETHOD],[MAXCORNERANGLE],[SAVESTANDARDSAUDIT],[ADDRESS5],[ADDRESS6],[PARENT],[SPSACCOUNTNUM],[SPSCOSTCENTER],[SPSRETURNLABEL],[AMSTRATEGYKEY],[TEMPFORASN],[MIXEDLPNPUTSTRATEGY],	[GROUPFTEACHDFLT],[ALLOCATEFTONCLOSE],[SPS_SCAC],[SPSAPISTRATEGYKEY],[PRINTPACKLIST],[PRINTPACKTEMPLATE],[PRINTCONTENTSREPORT],[PKTRACKINGID],[AUTOPRINTADDRESSLABEL],[AUTOPRINTORDERLABELS],[LOCALE],[PAYROLLPERIOD],	[INITIALPAYROLLPERIODENDDATE],[PAYROLLEXTRACTFOLDER],[INCREMENTALEXTRACT],[DAYBOUNDARYMINUTES],[AUTOMATICFIRSTACTIVITY],[VENDORCOMPLYSTRATEGYKEY],[BACKORDER],[BOTYPE],[DEFAULTTRANSPORTATIONSERVICE],[DEFAULTEQUIPMENTATTRIBUTE],	[DEFAULTEQUIPMENTTYPE],[DEFAULTEQUIPMENTLENGTH],[MIXPALLETPUTAWAYMETHOD],[DFLTEQUIPMENTFORASSGN],[DFLTEQUIPMENTFORPALLET],[RFAUTOFILLRCVLPN],[INBOUNDLPNLENGTH],[INBOUNDLPNPREFIX],[RFRCVAUTOPRINTLPN],[RECEIPTUNITLABELNAME],[RECEIPTUNITLABELUOM],	[LASTSHIPPEDLOTCTRL],[ALLOCATIONLOTLIMIT],[OUTLABELSREQUIREDTOSHIP],[OUTLABELSREQUIREDTOBOL],[OUTBOUNDLABELSLEVEL],[OUTBOUNDLABELSCOUNTLEVEL],[STANDARDOUTBOUNDLABELPREFIX],[USEPARTNERLPNCONTROL],[EXTERNSTORERKEY],[AUTOFINALIZEPRODORDER],	[CREATEMOVESFROMPROD],[PRODCOUNTLOC],[DEFAULTNEWALLOCATIONSTRATEGY],[MINSHELFLIFEOVERRIDEPCT],[adddate],addwho,editdate,editwho)	
	SELECT [WHSEID],@short_name,[TYPE],[SOURCEVERSION],@long_name,[VAT],[ADDRESS1],[ADDRESS2],[ADDRESS3],[ADDRESS4],[CITY],[STATE],[ZIP],[COUNTRY],[ISOCNTRYCODE],[CONTACT1],[CONTACT2],[PHONE1],[PHONE2],[FAX1],[FAX2],[EMAIL1],[EMAIL2],[B_CONTACT1],[B_CONTACT2],[B_COMPANY],[B_ADDRESS1],[B_ADDRESS2],[B_ADDRESS3],[B_ADDRESS4],[B_CITY],[B_STATE],[B_ZIP],[B_COUNTRY],[B_ISOCNTRYCODE],[B_PHONE1],[B_PHONE2],[B_FAX1],[B_FAX2],[B_EMAIL1],[B_EMAIL2],[CREDITLIMIT],[CARTONGROUP] = 'STD',[PICKCODE],[CREATEPATASKONRFRECEIPT],[CALCULATEPUTAWAYLOCATION],[STATUS],[DEFAULTSTRATEGY],[DEFAULTSKUROTATION],[DEFAULTROTATION],[SCAC_CODE],[TITLE1],[TITLE2],[DESCRIPTION],[SUSR1],[SUSR2],[SUSR3],[SUSR4],[SUSR5],[SUSR6],[MULTIZONEPLPA],[CWOFLAG],[ROLLRECEIPT],[NOTES1],[NOTES2],[APPORTIONRULE],[ENABLEOPPXDOCK],[ALLOWOVERSHIPMENT],[MAXIMUMORDERS],[MINIMUMPERCENT],[ORDERDATESTARTDAYS],[ORDERDATEENDDAYS],[ORDERTYPERESTRICT01],[ORDERTYPERESTRICT02],[ORDERTYPERESTRICT03],[ORDERTYPERESTRICT04],[ORDERTYPERESTRICT05],[ORDERTYPERESTRICT06],[OPPORDERSTRATEGYKEY],[RECEIPTVALIDATIONTEMPLATE],[ALLOWAUTOCLOSEFORPO],[ALLOWAUTOCLOSEFORASN],[ALLOWAUTOCLOSEFORPS],[ALLOWSYSTEMGENERATEDLPN],[ALLOWDUPLICATELICENSEPLATES],[ALLOWCOMMINGLEDLPN],[LPNBARCODESYMBOLOGY],[LPNBARCODEFORMAT],[ALLOWSINGLESCANRECEIVING],[LPNLENGTH],[APPLICATIONID],[SSCC1STDIGIT],[UCCVENDORNUMBER],[CASELABELTYPE],[AUTOPRINTLABELLPN],[AUTOPRINTLABELPUTAWAY],[LPNSTARTNUMBER],[NEXTLPNNUMBER],[LPNROLLBACKNUMBER],[BARCODECONFIGKEY],[DEFAULTPUTAWAYSTRATEGY],[AUTOCLOSEASN],[AUTOCLOSEPO],[TRACKINVENTORYBY],[DUPCASEID],[DEFAULTRETURNSLOC]= 'RETURNS',[DEFAULTQCLOC],[PISKUXLOC],[CCSKUXLOC],[CCDISCREPANCYRULE],[CCADJBYRF],[ORDERBREAKDEFAULT],[SKUSETUPREQUIRED],[DEFAULTQCLOCOUT],[ENABLEPACKINGDEFAULT],[DEFAULTPACKINGLOCATION],[GENERATEPACKLIST],[PACKINGVALIDATIONTEMPLATE],[INSPECTATPACK],[ADDRESSOVERWRITEINDICATOR],[ACCOUNTINGENTITY],[CREATEOPPXDTASKS],[ISSUEOPPXDTASKS],[OPPXDPICKFROM],[OBXDSTAGE],[KSHIP_CARRIER],[SPSUOMWEIGHT],[SPSUOMDIMENSION],[DEFDAPICKSORT],[DEFRPLNSORT],[REQREASONSHORTSHIP],[EXPLODELPNLENGTH],[EXPLODELPNROLLBACKNUMBER],[EXPLODELPNSTARTNUMBER],[EXPLODENEXTLPNNUMBER],[OWNERPREFIX],[CONTAINEREXCHANGEFLAG],[CARTONIZEFTDFLT],[DEFFTLABELPRINT],[DEFFTTASKCONTROL],[MEASURECODE],[WGTUOM],[DIMENUOM],[CUBEUOM],[CURRCODE],[TAXGROUP],[DEFCORPCODE],[SURCHGBASETEMP],[AMBTEMPERATURE],[INVOICETERMS],[ARCORP],[ARDEPT],[ARACCT],[INVOICELEVEL],[NONNEGLEVEL],[TAXID],[DUNSID],[RECURCODE],[QFSURCHARGE],[BFSURCHARGE],[TAXEXEMPT],[TAXEXEMPTCODE],[TIMEZONE],[PLANDAYS],[ARCHIVEPLANNINGDAYS],[ARCHIVEREPORTINGDATA],[PLANENABLED],[DEFAULTHOURLYRATE],[DISTCALCMETHOD],[MAXCORNERANGLE],[SAVESTANDARDSAUDIT],[ADDRESS5],[ADDRESS6],[PARENT],[SPSACCOUNTNUM],[SPSCOSTCENTER],[SPSRETURNLABEL],[AMSTRATEGYKEY],[TEMPFORASN],[MIXEDLPNPUTSTRATEGY],[GROUPFTEACHDFLT],[ALLOCATEFTONCLOSE],[SPS_SCAC],[SPSAPISTRATEGYKEY],[PRINTPACKLIST],[PRINTPACKTEMPLATE],[PRINTCONTENTSREPORT],[PKTRACKINGID],[AUTOPRINTADDRESSLABEL],[AUTOPRINTORDERLABELS],[LOCALE],[PAYROLLPERIOD],[INITIALPAYROLLPERIODENDDATE],[PAYROLLEXTRACTFOLDER],[INCREMENTALEXTRACT],[DAYBOUNDARYMINUTES],[AUTOMATICFIRSTACTIVITY],[VENDORCOMPLYSTRATEGYKEY],[BACKORDER],[BOTYPE],[DEFAULTTRANSPORTATIONSERVICE],[DEFAULTEQUIPMENTATTRIBUTE],[DEFAULTEQUIPMENTTYPE],[DEFAULTEQUIPMENTLENGTH],[MIXPALLETPUTAWAYMETHOD],[DFLTEQUIPMENTFORASSGN],[DFLTEQUIPMENTFORPALLET],[RFAUTOFILLRCVLPN],[INBOUNDLPNLENGTH],[INBOUNDLPNPREFIX],[RFRCVAUTOPRINTLPN],[RECEIPTUNITLABELNAME],[RECEIPTUNITLABELUOM],[LASTSHIPPEDLOTCTRL],[ALLOCATIONLOTLIMIT],[OUTLABELSREQUIREDTOSHIP],[OUTLABELSREQUIREDTOBOL],[OUTBOUNDLABELSLEVEL],[OUTBOUNDLABELSCOUNTLEVEL],[STANDARDOUTBOUNDLABELPREFIX],[USEPARTNERLPNCONTROL],[EXTERNSTORERKEY],[AUTOFINALIZEPRODORDER],[CREATEMOVESFROMPROD],[PRODCOUNTLOC],[DEFAULTNEWALLOCATIONSTRATEGY],[MINSHELFLIFEOVERRIDEPCT],getdate(),'ben',getdate(),'ben'
	FROM [scprd].[wmwhse2].[STORER] WHERE type='1' AND [STORERKEY] = 'TLE'




INSERT INTO [SCPRD].enterprise.PARTNERFACILITYCONTROL (WHSEID, STORERKEY, STORERTYPE, ENABLED, REMOVE,[adddate],addwho,editdate,editwho) SELECT @WAREHOUSE,@short_name,'1','1','0',getdate(),'ben',getdate(),'ben'
If @WAREHOUSE = 'SCPRD_wmwhse1' 
	BEGIN INSERT INTO [SCPRD].wmwhse1.PARTNERFACILITYCONTROL (WHSEID, STORERKEY, STORERTYPE, ENABLED, REMOVE,[adddate],addwho,editdate,editwho) SELECT @WAREHOUSE,@short_name,'1','1','0',getdate(),'ben',getdate(),'ben' END
ELSE
	BEGIN INSERT INTO [SCPRD].wmwhse2.PARTNERFACILITYCONTROL (WHSEID, STORERKEY, STORERTYPE, ENABLED, REMOVE,[adddate],addwho,editdate,editwho) SELECT @WAREHOUSE,@short_name,'1','1','0',getdate(),'ben',getdate(),'ben' END
	

------------------------------------------
-- API Credentials Setup 
-------------------------------------------

If @api = 'Yes' 
Begin

	INSERT INTO Enterprise.dbo.ApiClient
			( fulfillment_id, name, description, auth_token, auth_key                        , delete_flag, mapped_flag, add_who , add_date , edit_who, edit_date)
	VALUES	(@fulfillment_id,@short_name,@long_name, newid()   , left(replace(newid(),'-',''),20), 0          , 0          , 'Creator', getdate(), 'Creator', getdate())

	Insert into Enterprise.dbo.Fulfillment_Properties
	SELECT top 1 @fulfillment_id,[property_group],[property_name],[property_value],GETDATE(),'Creator',GETDATE(),'Creator'
	FROM Enterprise.dbo.Fulfillment_Properties where property_name = 'order_explode_kit_items'

End

Update enterprise.dbo.sequence set sequence = @fulfillment_id where seq_name = 'fulfillment'

/* 					IMPORTANT!!!	IMPORTANT!!!	IMPORTANT!!!
 					IMPORTANT!!!	IMPORTANT!!!	IMPORTANT!!!
	 					IMPORTANT!!!	IMPORTANT!!!	IMPORTANT!!!
						 open this proc below and run it after main script runs
					lebanon.dbo.pr_Fulfillment_Copy_Wizard_Local	 
*/			
-- this proc failed in many places as noted above. run everything in UAT first. it is meant
-- to be ran as a single execution and should produce 10 separate (1 row affected) messages
-- otherwise there will be errors and wasted time.
-- also notes for excel usage ctrl shift hot keys provide dynamic row manipulation.
-- lookup extra usage for these to make 

-- insert not working yet but this is for copying roles over from tle to zevo
-- need to figure out how to specify ff id of 1166(zevo) to insert into
insert lebanon.dbo.fulfillment_role(
	   [role_id]
      ,[role_name]
      ,[role_ids]
      ,[role_level])
  FROM MASON.[dbo].[Fulfillment_Role]
  where fulfillment_id = 901

-- here is correct insert
-- to use: manually add the role id name by clicking white space and declaring
-- after name is made id auto populates and use this for the insert select stmt
insert into role_security
select top 100 1580/* replace 1580 with new role id*/, security_context, security_role
from fulfillment_role fr
JOIN Role_Security rs on rs.role_id= fr.role_id
where rs.role_id = 1282 -- role id we are taking security infor from

-- starting to copy items over from tle
-- first query to check item cost center vs ff cost center not a 1 1 match
select top 1000 i.cost_center, l.item_cost_center, *
from mason.dbo.lineitem l(nolock)
join mason.dbo.inventory i (nolock) on i.fulfillment_id = l.fulfillment_id
where l.fulfillment_id = 901
and i.cost_center = 'zevo'
-- means we probably need to take all skus from tle for zevo.

-- root cause of Zevo not working in prod is that i inserted corporate users id over administrator
-- so it thought i wasnt an admin and my roles were messed up. needed cory and james help to
-- dig and see where the issue was. shouldnt need their help for small little details
-- at first hint of role issue VERIFY IDS MATCH ROLES -- this goes for all unique keys
-- cory did create a cool query to run the stor proc dataform_copy
-- basically made the full query, of which i only have part, by building what the proc needs
-- from parameters then also getting the role_ids needing to be copied to new fulfillment
-- he then copied some query results over to N++ and formatted with some sort of carriage return
-- and took these role id results and put into original query

case when role_ids like '%1282%' then '1580' else '' end -- these are not complete dont copy randomly
case when role_ids like '%1285%' then '1583' else '' end -- these are not complete dont copy randomly
case when role_ids like '%3435%' then '1232' else '' end -- these are not complete dont copy randomly
-- uses case when for dif role inserts
0 from enterprise.dbo.dataformfulfillment dff (nolock)
where dff.role_ids

/* notes for ticket issues with VAY processes and orders.
orders are B2B and in larger quanitites but not sending 855 or 856s and were stuck in allocated.
in nav. For Vayyar we have to capture serial numbers (which is found in infor pick detail 
catch weight/data) for every single quantity in an order
and usually this means OPS has to scan an item 40 times or however much the batch is.
the problem is that we arent going to get ops or anyone to scan a pallet (1600) or more times
for every item on it. Therefor whatever they didnt scan we need to find a process or something
to assist in this whereas we usually send small scan numbers to ops for B2C.

In this case we struggled to find how to do such a task until querying around while trying
to make a new stored proc to assist us. Turns out there is a store proc named
pr_Create_CatchData that does this partially so we have something to work off of.
so now i started changing this proc which is setup to run only in wmwhse2 to wmwhse1 and 
any dbo from mason to lebanon.

There is also a lot of fluff and useless things that werent exactly helping us form a
solid proc that wont effect other results and only change a few fields. For example:
the insert into wv for wave pick is not needed as well as the insert for wave mass ship.
Also, commenting out some where clauses like order_type in prod or scrap or ship meth 90001.
Commenting out not exists(select 1 from..). Another issue we ran into was the store proc
inside this one called wmwhse1.pr_NCOUNTER_Nextvalue for 'autopickserial' which helped
to create and index but the version for wh1 leb was never set up like wh2 mason.
To fix this we looked to see what data was needed to run and noticed nothing was populating
in a NOT NULL that required data. so we hard coded the data and it allowed us to get
 over this issue that halted running the main store proc. 

Lastly, a couple different things, we had to hard code in the select that the serial number
 fields oother1 and serialnumberlong had the same serial num that some of the original 
 scans for this item received in infor. And the add and edit who as'exe' which is a value
we gave in NCOUNTER. Also, the iqty 0, oqty 1, and normal qty(pd.qty) as the exact amount
we needed, in this case 1432 and in a couple different orders. had to do an update a couple
times because i put serial number from one order in another. here is that update

--update l
set OOTHER1 = 'CN180419242121',
	serialnumberlong = 'CN180419242121'

from wms_ORDERS o (nolock)
join wms_PICKDETAIL p (nolock) on p.ORDERKEY = o.orderkey
join [scprd].wmwhse1.LOTXIDDETAIL l (nolock) on l.PICKDETAILKEY = p.PICKDETAILKEY
where o.EXTERNORDERKEY = 'VA0000031701'
and l.ADDWHO = 'exe'

in summary it helped ship the items because this is the root cause of the inverse.
Apparently part of the issue is a 856 not being sent but will check to see if
ship complete in infor triggered this.
extra code
use LEBANON
-- tickets for amazon vayyar 12988 12986 12989
select *
from orders (nolock)
where primary_reference = 'VA0000031699'
-- item id? DY20BCGL01 sku

select *
from Lineitem (nolock)
where order_primary_reference = 'VA0000031701'

select *
from orders o (nolock)
join wms_orders wo (nolock) on wo.EXTERNORDERKEY = o.primary_reference
where o.primary_reference = 'VA0000031699'

select *
from wms_LOTXLOCXID (nolock)
where STORERKEY = 'VAY'
and SKU = 'DY20BCGL01'

select l.*
from wms_ORDERS o (nolock)
join wms_PICKDETAIL p (nolock) on p.ORDERKEY = o.orderkey
join wms_LOTXIDDETAIL l (nolock) on l.PICKDETAILKEY = p.PICKDETAILKEY
where o.EXTERNORDERKEY = 'VA0000031701'
and p.PICKDETAILKEY = '0061131074'
and p.SKU = 'DY20BCGL01'
and l.SERIALKEY > 55961

0061131059

pd.qty - (select count(*)from wmwhse1.LOTXIDDETAIL where PICKDETAILKEY = pd.PICKDETAILKEY)

*/

/* 							Ticket ATP-13005 								
							build boomi process for jira tickets emails 
reading notes on how to section for building processes on boomi
tips:
-what does the source data look like and what does the destination data need to look
like in terms of fields, format, structure and delimiters?
answers from est meeting -

-wht mapping, transformations, lookups, ets need to be performed to get the data from 
source to destination?
answers from est meeting -


api calls to get and send emails? going to use cache and looping for data storage
going to export as csv to attach to emails

*/

/* more notes for mock recall report ATP-12883
rollup process?
not just for cpg - we need to be able to find the logic and figure out how its going to 
either work for this report or remove some of reports functionality?
-- james helped find proc
its a store proc / job that used to be scheduled but is no longer running
it would do as brian described in email. limiting the archive data.. this ended in 2016 so no
rollups should exist after then

updating this now 11/13/18 - 11/30/18 

too busy prior to this week 11/30
working on this now made 2nd proc in UAT 1 for archive 1 not
changed the inserts into temp tables from:
BEGIN
	INSERT INTO #lots
	SELECT lot 
	FROM wms_ITRN
	WHERE storerkey = @storerkey
		AND sku = @lotList
END

TO:
BEGIN
	SELECT lot 
	INTO #lots
	FROM wms_ITRN_ALL
	WHERE storerkey = @storerkey
		AND sku = @lotList
END
UAT
seems to be helping runtime in UAT at least. 03537522 sku ran for 2:16
from 1/1/17 to 10/18/18 900 rows
UAT
2nd sku 03535780 ran 1:57 from 1/1/17 to 10/18/18 2610 rows no from or to lots

prod version with old insert 
sku 03537522 run 9:46 from 1/1/17 to 10/18/18 3827 rows

UAT
SKU 03535508 2017-01-01 - 2018-10-18
pulled into crystal to try to run through here to help optimize

need to check if any of the skus given can find and transfer to or from lots
data. gotta try very specific queries

prod test with rebuild 12/13/18
using sku 03537522
query cancelled at 39min 19 sec with 260738 rows
rebuild doesnt include create proc, declare, first select, and the if statement

worked with james on why archive data was running so slow. after picking apart stored proc it 
wasnt an issue with the proc itself but the archive indexes for the report data

highlight proc and right click dispaly estimated execution plan
highlighted in green will be a message saying
index data missing
right click the report area where it says its missing and select missing indexes
run the query inside the comments.
indexes should be cleaned up enough to run the proc faster

however today 12/14/18 when we worked on exactly this ^
the report wouldnt run within a few minutes. going over 10 currently

so it seems after rewriting again using different selects into #final
it was still taking too long and after commenting out #lots join 
it was actually able to pull data even though inefficiently.

so have to optimize or figure out how to change the #lots join


/*								ticket atp-13030
								orders bypassing child meter
*/
http://afstms01/vxe/


-- using this to locate orders with zevo distinction susr2
select top 1000 *
from mason.dbo.wms_ORDERS (nolock)
where storerkey = 'tle'
and SUSR2 = 'zevo'
and ADDDATE < '8-9-2018'
order by ADDDATE desc

-- TL0000075667
-- trying to solve for freight charge issues where aero is being billed instead of tle

select top 100 *
from ENTERPRISE.dbo.Freight_Client (nolock)
where order_primary_reference = 'TL0000047013'


select top 100 *
from ENTERPRISE.dbo.Freight_Invoicedetail (nolock)
where Reference1 = 'TL0000047013'

-- cant find the reason 
-- update worked with filipe and made sure to use correct db to query prim ref from
-- excel sheet to query against. DMSServer.wmwhse2.dbo. 
-- just do same query with prim ref for invoice and itll show the ship service

/* 									ticket atp-13016
									incorrect receipt reversal
found receipt reversal in infor after being unable to find anything like a process for it
in boomi.		
*/

/*									ticket ATP-13004
									aptos aos orders need to verify ship confirm
									helping on archana's ticket
APtos is aos shopify type orders. lineitem tracking not the same as order tracking

CASE WHEN len(isnull(m.trackingnumber, '')) < 30 THEN ISNULL(m.trackingnumber, '') ELSE '' END AS trackingnumber,

was going to use sql from boomi stor proc to find timestamp and then locate 
correct process with the tracking numbers in ticket 

-- archana's ticket atp-13004 aptos

select	ft.trans_id, 
	o.primary_reference, 
	o.customer_reference, 
	o.order_date, 
	ISNULL(o.ship_date, '') AS ship_date, 
	CASE WHEN o.order_status IN ('ERROR', 'CANCELED', 'SKIPPED') THEN 'CANCELED' ELSE 'SHIPPED' END AS order_status, 
	'shipmethod' = CASE o.ship_method_id WHEN 19010 THEN 'STANDARD' when 11008 then 'EXPRESS' when 11014 then 'RUSHED' when 19018 then '19018' when 11003 then '11003' when 11015 then '11015' when 19012 then '19012' when 13023 then '13023' else 'STANDARD' END, 
	o.consign, 
	o.ship_attention, 
	o.ship_address_1, 
    o.ship_address_2, 
	o.ship_city, 
	o.ship_region, 
	o.ship_postal_code, 
	o.ship_country, 
	o.phone, 
	ISNULL(o.email, '') AS email, 
	l.line_number, 
	l.item_primary_reference, 
	CONVERT(int, l.qty_ordered / ISNULL(pd.Units, 1)) AS qty_ordered, 
	CONVERT(int, l.qty_shipped / ISNULL(pd.Units, 1)) AS qty_shipped, 
	'line_status' = CASE WHEN l.line_status IN ('ERROR', 'CANCELED', 'SKIPPED') THEN 'CANCELED' WHEN l.line_status = 'SHIPPED' AND l.qty_shipped = 0 THEN 'CANCELED' ELSE 'SHIPPED' END, 
	ISNULL(lx.flexfield1, l.line_number) AS lineid, 
	CASE WHEN len(isnull(m.trackingnumber, '')) < 30 THEN ISNULL(m.trackingnumber, '') ELSE '' END AS trackingnumber,
     'qty_sent' = (SELECT SUM(lt.qty_shipped) AS Expr1 FROM dbo.Lineitem AS lt INNER JOIN dbo.Orders AS ot ON lt.orders_id = ot.orders_id WHERE (ot.primary_reference = o.primary_reference)), 
	lx.flexfield3 AS ItemID
FROM 
	Orders o (nolock) 
	INNER JOIN Fulfillment_Transaction ft (nolock) ON o.orders_id = ft.trans_key01 AND o.order_status = ft.trans_submodule 
	INNER JOIN Lineitem l (nolock) ON o.orders_id = l.orders_id 
	INNER JOIN Lineitem_FlexFields lx (nolock) ON l.lineitem_id = lx.lineitem_id 
	INNER JOIN Inventory i (nolock) ON l.item_id = i.item_id 
	LEFT  JOIN Inventory_PackDetail pd (nolock) ON l.packkey = pd.Packkey AND l.uom = pd.UOM 
	INNER JOIN Orders_Batch ob (nolock) ON o.orders_id = ob.orders_id 
	INNER JOIN Batch b (nolock) ON ob.batch_id = b.batch_id 
	LEFT  JOIN vw_Manifest m (nolock) ON o.primary_reference = m.order_primary_reference
WHERE       
	o.fulfillment_id = (select fulfillment_id from fulfillment where short_name = 'AOS')
	AND ft.trans_module = 'ORDERS' 
	--AND ft.trans_submodule = 'SHIPPED' 
	AND ft.trans_date > CASE --'2015-12-01 17:30:00.000'  
							WHEN @@SERVERNAME = 'AFSSQL01'
							THEN DATEADD(MONTH, -3, GETDATE())
							ELSE DATEADD(MONTH, -36, GETDATE())
						END
	--AND ft.trans_status = '0' 
	AND (b.batch_reference = 'AOSXML' 
        or b.external_batch_id  like 'AOS_ECOM%' )
	--AND b.batch_date > '2013-10-20' 
	AND LEN(RTRIM(ISNULL(m.trackingnumber, ''))) BETWEEN 0 AND 29
	and l.qty_shipped > 0
	and o.add_date > '2018-10-10 15:01:44.927'
ORDER BY customer_reference--, lineid


*/									
/* 									ci-163 and CI-164 
									RAS / TAOS tests
notes 

-- update [scprd].wmwhse1.lotattribute
set lottable04 = '2018-01-01 06:00:00.000'
where SKU = '80232108'
and lot = '0000186295'

-- shelf life issues

--update l set l.lottable04 = '2018-01-01 06:00:00.000'
--select lottable04, * 
from [scprd].wmwhse1.lotattribute l
where SKU = '80232108'
and lot = '0000186295'

^^^ for above bottom update worked and normal update statement im used to didnt. 
remember to look up various ways to write updates. this hung up the process of working on
test orders.

*/

/* 									ATP-12994
									ras 945 needs to send ship confirm even if whole order
									zero ships
 believe this is an issue with join

 FROM #orders ord
	JOIN Orders o (nolock) ON ord.orders_id = o.orders_id
	JOIN Orders_Flexfields ox (nolock) ON o.orders_id = ox.orders_id
	JOIN Lineitem l (nolock) ON o.orders_id = l.orders_id	
	JOIN Lineitem_Flexfields lx (nolock) ON l.lineitem_id = lx.lineitem_id
	JOIN Inventory i (nolock) ON l.item_id = i.item_id
	JOIN Inventory_Flexfields ix (nolock) ON i.item_id = ix.item_id
	left join Ship_Method s on s.ship_method_id = o.ship_method_id
	LEFT JOIN SCPRD.wmwhse1.ORDERDETAIL od (nolock) ON l.order_primary_reference = od.externorderkey AND l.line_number = od.externlineno
	LEFT JOIN ( --roll up by line and case so we have one case linked to each line
			SELECT  orderkey,orderlinenumber,caseid, lat.LOTTABLE08, sum(convert(int, pd.qty)) as 'qty_shipped'
			FROM SCPRD.wmwhse1.PICKDETAIL pd (nolock)
			inner join scprd.wmwhse1.LOTATTRIBUTE lat with (nolock)
				on lat.LOT = pd.LOT and lat.SKU = pd.SKU	-- vvvvvvvvvvvvvvvvvvvvvv
			WHERE pd.storerkey = 'RAS' and status='9'-- and qty > 0 -- RIGHT HERE with the QTY >0
			GROUP BY lat.LOTTABLE08,orderkey, orderlinenumber, caseid --^^^^^^^^^^^^^^^^^^^^^
		) pd ON od.orderkey = pd.orderkey AND od.orderlinenumber = pd.orderlinenumber
	JOIN (  --get case trackingnumber
			SELECT order_primary_reference, caseid,	trackingnumber=max(trackingnumber), bol=max(bol)	--for safety
			FROM vw_Manifest (nolock) 
			WHERE order_primary_reference like 'RA%'
			GROUP BY order_primary_reference, caseid
		) m ON o.primary_reference = m.order_primary_reference 	AND pd.caseid = m.caseid
	JOIN (  --get alternate trackingnumber in case they consolidated caseids
			SELECT order_primary_reference, trackingnumber=max(trackingnumber)
			FROM vw_Manifest (nolock) 
			WHERE order_primary_reference like 'RA%'
			GROUP BY order_primary_reference
		) ma ON o.primary_reference = ma.order_primary_reference  AND o.order_status = 'SHIPPED'	--not ERROR
	JOIN ship_method sm (nolock) ON o.ship_method_id = sm.ship_method_id
WHERE o.fulfillment_id = 1087
and ox.flexfield28 = 'RAS_EDI_ORDERS'
ORDER BY l.line_number, PD.CASEID, coalesce(m.trackingnumber,ma.trackingnumber,'NA')


-- trying to write query to see which orders need to be reset to 0 for trans_submodule to trigger 945 to send.
	select *
	from orders o(nolock)
	join Lineitem l(nolock) on l.orders_id = o.orders_id
	join Fulfillment_Transaction f(nolock) on f.trans_key01 = o.orders_id
	where o.fulfillment_id = 1087
	and l.qty_shipped = 0
	and o.order_date > '10-01-2018'
	and f.trans_submodule = 'SHIPPED'

	select top 1 * from Fulfillment_Transaction (nolock)
	select top 1 * from OrdersEdit (nolock)
	select top 1 * from Orders_FlexFields (nolock)
	
	select *
	from orders o(nolock)
	join OrdersEdit e(nolock) on e.orders_id = o.orders_id
	--join Lineitem l(nolock) on l.orders_id = o.orders_id
	where o.fulfillment_id = 1087
	and e.ship_amt = 
	--and l.qty_shipped = 0
	and o.order_date > '10-01-2018'
*/

/* 									ATP-13070
									RAS order stuck as part shipped
									in infor item is picked but wont ship
									doesnt give error when it doesnt ship

james had me search several places to try to finds where the error could be. shown in these queries
had to use serialkey which never seemed to work but also sku and prim ref. has a dropid and 
caseid. trading partner = wave

key sources wms_apiresponse, manifest and found a proc in scprd or leb for skuxloc fix and it is
bottom queries just trying to select instead of update like the proc wanted to do
- wmwhse1.pr_FixSKUxLOCConstraintError

select top 1 * from Manifest (nolock)
where order_primary_reference = 'RA0000039271'
select top 1 * from Lineitem (nolock)

select top 10 * from lebanon.dbo.wms_API_RESPONSE (nolock) where SERIALKEY = 22107022

-- in (24665465,
--24661561,
--24661563,
--24661564)

select *
from wms_ORDERDETAIL_all (nolock)
where EXTERNORDERKEY = 'RA0000039271'

select *
from orders o(nolock)
join LineitemEdit l(nolock) on l.orders_id = o.orders_id
where o.primary_reference = 'RA0000039271'

select *
from wms_ORDERSTATUSHISTORY
where SERIALKEY in (24665465,
24661561,
24661563,
24661564)

select *
from wms_LotxLocxID_All (nolock)
where SKU = '81502853'
and SERIALKEY = '22106508'

use scprd
go

select *
FROM wmwhse1.Pickdetail pd
INNER JOIN wmwhse1.Orderdetail od with (nolock)
	ON pd.orderkey = od.orderkey
	AND pd.orderlinenumber = od.orderlinenumber
WHERE pd.sku = '81502853'
	AND pd.loc = 'PICKTO'
	and pd.WAVEKEY = 0000319143
	--AND pd.status in ('5','6')
	and pd.CASEID = '0070738421'
	AND od.status = '95'

-- using wavekey it did not pull my specific stuck order when it should have i believe
	
use scprd
go

select *
FROM wmwhse1.Pickdetail pd
INNER JOIN wmwhse1.Orderdetail od with (nolock)
	ON pd.orderkey = od.orderkey
	AND pd.orderlinenumber = od.orderlinenumber
WHERE pd.sku = '81502853'
	AND pd.loc = 'PICKTO'

-- summary this seemed to be caused by OPS somehow configuring or hitting wrong things
-- while scanning with RF Gun which caused corrupt tables and items that infor had to fix themselves

*/

/* 									ATP-13075
									ras 945 not showing same orders that came in on 940
									could be issue with this stor proc from 940 or get from 945
									otherwise may be mapping
dx_RAS_EDI940_PostProcess

-- query for viewing line item trans from 945 get proc -- removed extra stuff that
-- was trying to allocate lines or group by orders_id


select *
FROM Orders o (nolock)
	JOIN Lineitem l(nolock) ON o.orders_id = l.orders_id	
	JOIN fulfillment_transaction ft (nolock) ON o.orders_id = ft.trans_key01
	JOIN Orders_Batch ob (nolock) ON o.orders_id = ob.orders_id
	JOIN Batch b (nolock) ON ob.batch_id = b.batch_id
WHERE o.fulfillment_id = 1087
	--AND o.order_status = 'ERROR'
	AND o.release_date > CASE WHEN @@SERVERNAME = 'AFSSQL01' THEN GETDATE()-30 ELSE GETDATE()-365 END 
	--AND b.external_batch_id like 'RAS940%' --exclude manual orders & 3PL orders
	--AND l.line_status = 'ERROR'
	--AND l.approval_reason like 'Lineitem Allocation%'
	AND ft.trans_module = 'ORDERS' 
	--AND ft.trans_submodule = 'ERROR'
	and o.customer_reference = 'ORD0002790' --for testing. comment this line out for prod.
	--AND isnull(ft.trans_status,'0') = '0'  
-- UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE
-- with joshes help i was shown another method to piece a proc together to see
-- where it was or wasnt working
-- used a select against the #orders after each section of selects to pinpoint issues
-- in this case first 2 selects worked just last one wasnt because of joins
-- example select 'FirstQuery',* from #orders -- put this right after first select

/*
	Retail Art Of Shaving  EDI 945 - Ship Confirmation

	Get orders eligible to confirm including ERROR due to item allocation failure
	The main difference is in the fulfillment_transaction log record we mark.

*/

--using temp table vs. table variable cut runtime from 32secs to 5secs
CREATE TABLE #orders(orders_id int, trans_id int)

--Production version 6/10/2015
INSERT INTO #orders
SELECT o.orders_id, ft.trans_id
FROM Orders o (nolock)
	JOIN fulfillment_transaction ft (nolock) ON o.orders_id = ft.trans_key01
	JOIN Orders_Batch ob (nolock) ON o.orders_id = ob.orders_id
	JOIN Batch b (nolock) ON ob.batch_id = b.batch_id
WHERE o.fulfillment_id = 1087
	AND o.order_status = 'SHIPPED'
	AND o.ship_date > CASE WHEN @@SERVERNAME = 'AFSSQL01' THEN GETDATE()-30 ELSE GETDATE()-365 END 
	AND b.external_batch_id like 'RAS%' --exclude manual orders & 3PL orders
	AND ft.trans_module = 'ORDERS' 
	AND ft.trans_submodule = 'SHIPPED'
	and o.customer_reference = 'ORD0002790' --for testing. comment this line out for prod.
	--AND isnull(ft.trans_status,'0') = '0'								--uncomment for prod.
	--and ft.trans_date > '2018-07-13'
	select 'FirstQuery',* from #orders -- used to see where proc pulls data correctly
--Add lineitem allocation failures (ERROR status)
INSERT INTO #orders
--should only be one line in error, and one ft error record, but for safety...
SELECT o.orders_id, trans_id = max(ft.trans_id)
FROM Orders o (nolock)
	JOIN Lineitem l(nolock) ON o.orders_id = l.orders_id	
	JOIN fulfillment_transaction ft (nolock) ON o.orders_id = ft.trans_key01
	JOIN Orders_Batch ob (nolock) ON o.orders_id = ob.orders_id
	JOIN Batch b (nolock) ON ob.batch_id = b.batch_id
WHERE o.fulfillment_id = 1087
	AND o.order_status = 'ERROR'
	AND o.release_date > CASE WHEN @@SERVERNAME = 'AFSSQL01' THEN GETDATE()-30 ELSE GETDATE()-365 END 
	AND b.external_batch_id like 'RAS940%' --exclude manual orders & 3PL orders
	AND l.line_status = 'ERROR'
	AND l.approval_reason like 'Lineitem Allocation%'
	AND ft.trans_module = 'ORDERS' 
	AND ft.trans_submodule = 'ERROR'
	AND isnull(ft.trans_status,'0') = '0'  
GROUP BY o.orders_id
ORDER BY 1
 select 'SecondQuery', * from #orders -- used to see where proc pulls data correctly
--Production version 6/10/2015
SELECT --o.primary_reference as AeroOrder#
	W0601 = 'F'	--F = Full detail
	,W0602 = o.customer_reference				--PO number (940-W0503)
	,W0603 = convert(varchar,o.order_date,112)	--yyyymmdd
	,W0604 = ''									--Shipment ID#
	,W0605 = o.reference_3						--Depositor Order Number (940-W0502)
	,N101 = 'ST'
	,N102 = o.consign
	,N301 = o.ship_address_1
	,N302 = o.ship_address_2
	,N401 = o.ship_city
	,N402 = o.ship_region
	,N403 = o.ship_postal_code
	,N404 = o.ship_country
	,REF01 = case when s.service_name = 'LTL' then 'BM' else null end
	,REF02 = case when s.service_name = 'LTL' then m.bol else null end
	,G6201 = '11'
	,G6202 = convert(varchar,o.ship_date,112)
	,W2701 = 'M'
	,W2702 = case when o.ship_method_id = 11008 then 'FED2' when o.ship_method_id = 19010 then 'FEDG' when o.ship_method_id = 15040 then 'MITS' else sm.service_name end
	,W2703 = o.ship_method_id
	,W2704 = 'PP'	--ox.flexfield18	--case when isnull(o.ship_bill_account,'')<>'' then 'CC' else 'PP' end
	
	----------item detail section----------------
	,LX01 =	right('0000' + CONVERT(varchar, Row_Number() Over (ORDER BY l.line_number, PD.CASEID, coalesce(m.trackingnumber,ma.trackingnumber,'NA'))),5)	--dbo.emptynull(lx.flexfield1,l.line_number)
	,MAN01 = 'GM'
	,MAN02GM =	dbo.[SSCC18GS1]('0',
											case when [dbo].[GetRASLabelNumber](o.consign) in (8,3) then '0037000'
														else '0400000'
														end
											,
											case when [dbo].[GetRASLabelNumber](o.consign) = 8 then LTrim(RTrim(pd.caseid + '9'))
														else LTrim(RTrim(pd.caseid))
														end
											)
	,MAN01 = 'CP'
	,MAN02CP = rtrim(coalesce(m.trackingnumber,ma.trackingnumber,'NA'))
	,W1201 = case when o.ship_method_id=90005 then 'CP' when l.qty_shipped >= l.qty_ordered then 'CC' else 'CP' end
	,W1202 = l.qty_ordered
	,W1203 = case when o.ship_method_id=90005 then 0 else pd.qty_shipped end
	,W1204 = l.qty_ordered - case when o.ship_method_id=90005 then 0 else  l.qty_shipped end
	,W1205 = l.uom
	,W1206 = i.reference_4			--UPC case code
	,W1207 = 'VN'	--SK
	,W1208 = l.item_primary_reference
	--Optional segments...
	,G6901 = dbo.emptynull(lx.flexfield7,i.short_desc)
	,N902LT = pd.LOTTABLE08

	,ord.trans_id
FROM #orders ord
	left JOIN Orders o (nolock) ON ord.orders_id = o.orders_id
	left JOIN Orders_Flexfields ox (nolock) ON o.orders_id = ox.orders_id
	left JOIN Lineitem l (nolock) ON o.orders_id = l.orders_id	
	left JOIN Lineitem_Flexfields lx (nolock) ON l.lineitem_id = lx.lineitem_id
	left JOIN Inventory i (nolock) ON l.item_id = i.item_id
	left JOIN Inventory_Flexfields ix (nolock) ON i.item_id = ix.item_id
	left join Ship_Method s on s.ship_method_id = o.ship_method_id
	LEFT JOIN SCPRD.wmwhse1.ORDERDETAIL od (nolock) ON l.order_primary_reference = od.externorderkey AND l.line_number = od.externlineno
	LEFT JOIN ( --roll up by line and case so we have one case linked to each line
			SELECT  orderkey,orderlinenumber,caseid, lat.LOTTABLE08, sum(convert(int, pd.qty)) as 'qty_shipped'
			FROM SCPRD.wmwhse1.PICKDETAIL pd (nolock)
			inner join scprd.wmwhse1.LOTATTRIBUTE lat with (nolock)
				on lat.LOT = pd.LOT and lat.SKU = pd.SKU
			WHERE pd.storerkey = 'RAS' and status='9'-- and qty > 0 
			GROUP BY lat.LOTTABLE08,orderkey, orderlinenumber, caseid
		) pd ON od.orderkey = pd.orderkey AND od.orderlinenumber = pd.orderlinenumber
	left JOIN (  --get case trackingnumber
			SELECT order_primary_reference, caseid,	trackingnumber=max(trackingnumber), bol=max(bol)	--for safety
			FROM vw_Manifest (nolock) 
			WHERE order_primary_reference like 'RA%'
			GROUP BY order_primary_reference, caseid
		) m ON o.primary_reference = m.order_primary_reference 	AND pd.caseid = m.caseid
	left JOIN (  --get alternate trackingnumber in case they consolidated caseids
			SELECT order_primary_reference, trackingnumber=max(trackingnumber)
			FROM vw_Manifest (nolock) 
			WHERE order_primary_reference like 'RA%'
			GROUP BY order_primary_reference
		) ma ON o.primary_reference = ma.order_primary_reference  AND o.order_status = 'SHIPPED'	--not ERROR
	left JOIN ship_method sm (nolock) ON o.ship_method_id = sm.ship_method_id
	-- ^^ this join here was overall issue for orders that are zero shipped not getting ^^^^^^^
	-- ^^ a 945 sent. zero ships wont need tracking but the join wasnt functioning ^^^^^^
	-- ^^ the rest of the proc was fine so disregard other joins. this order had tracking ^^^^^
	-- ^^ because of a batch update that we no longer do. will update or delete somehow ^^^^^^^
WHERE o.fulfillment_id = 1087
and ox.flexfield28 = 'RAS_EDI_ORDERS'
ORDER BY l.line_number, PD.CASEID, coalesce(m.trackingnumber,ma.trackingnumber,'NA')

-- drop table #orders

*/

-- proper join for wms orders on orders - NAV JOIN INFOR ORDERS

select *
from lebanon.dbo.orders o (nolock)
left outer join lebanon.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
where o.primary_reference = 'RA0000039453'


/* 									ATP-13100
									item DC-106 weights not in equilibrium

documented in confluence link:
https://aerofulfillment.atlassian.net/wiki/spaces/INFOR/pages/503545870/Weights+must+be+in+equilibrium+erro

basically check and make sure all weights match. STDNETWGT1 and STDGROSSWGT1 are almost at end of
join so they are very far off right of screen

query & update looks like this 

select * 
from wms_sku_all s(nolock)
where sku = 'DC-106'

--update s
set STDNETWGT1 = '0.03800'
from wms_sku_all s(nolock)
where sku = 'DC-106'

3/28/19 jenny changed for order DL0000003374
messed the equilibrium up



--update s
set STDNETWGT1 = '0.3800',
	STDGROSSWGT1 = STDNETWGT1,
	STDGROSSWGT = STDNETWGT1,
	STDNETWGT = STDNETWGT1
from wms_sku_all s(nolock)
where sku = 'DC-106'


*/

/*									ATP-13142
									stuck batch for RAS
OSB type order that is stuck in batch_status 0
even though most of the actual orders are shipped - note these orders are old aside from about 34

same order keeps erroring because it didnt have ship1 addy on import
HOWEVER it somehow got a ship add 1 in nav and infor and the order is in both RA0000040713
so even though it errored and is stuck in allocated nav and released in infor its batch status is 0
do i just manually update batch status?

root cause:customer imported missing mand field and eventually reimported correctly
*/

/*
fix cost centers in windows nav

select *
from Fulfillment_Cost_Center f(nolock)
--join wms_SKU s (nolock) on s.
where fulfillment_id = 1166



--delete f
from fulfillment_cost_center f
where fulfillment_id = 1166
and cc_code <> 'ZEVO'
and cc_type = 'ORDERS'


--update f
set cc_code = 'RETAIL',
	cc_desc = 'RETAIL'
from fulfillment_cost_center f
where fulfillment_id = 1166
and cc_code = 'ZEVO'
and cc_type = 'ORDERS'

*/

/*							ATP-13155
							create check digits for ras locations
dylan gave us ras locations that needed check digits created and this scripts does that
ONLY if the locations are already created in infor. original list of 450ish
only created about 290 missing around 169. used second query for finding out which locations
werent created yet. afterwards had to run script again once dylan created those locs.							
*/
use scprd
go

/*

	SELECT DISTINCT
		   o.name AS Object_Name,
		   o.type_desc
	  FROM sys.sql_modules m
		   INNER JOIN
		   sys.objects o
			 ON m.object_id = o.object_id
	 WHERE m.definition Like '%checkdigit%';

*/
--select * from [aero].[LocationCheckDigits] lcd
--drop table #TempLCD
IF OBJECT_ID('tempdb..#TempLCD') IS NOT NULL 
	DROP TABLE #TempLCD
GO

SELECT        LOC, wmwhse1.calcLOCCheckDigit(LOC) AS CheckDigit
INTO              [#TempLCD]
FROM            wmwhse1.LOC AS l
WHERE        (LOC IN (
'640547010','640547020','640547030','640547040',
'640549010','640549020','640549030','640549040','640551010','640551020','640551030',
'640551040','640553010','640553020','640553030','640553040','640512040','640512030',
'640512010','640511040','640511030','640511020','640511010','640509040','640509030',
'640509020','640509010','640507040','640507030','640507020','640507010',
'640505040','640505030','640505020','640505010','640454040','640454030','640454010',
'640453040','640453030','640453020','640453010','640451040','640451030','640451020',
'640451010','640449040','640449030','640449020','640449010','640447040','640447030',
'640447020','640447010','640412040','640412030','640412010','640411040','640411030',
'640411020','640411010','640409040','640409030','640409020','640409010','640407040',
'640407030','640407020','640407010','640405040','640405030','640405020','640405010',
'640312040','640312030','640312010','640311040','640311030','640311020','640311010',
'640309040','640309030','640309020','640309010','640307040','640307030','640307020',
'640307010','640305040','640305030','640305020','640305010','640254040','640254030',
'640254010','640253040','640253030','640253020','640253010','640251040','640251030',
'640251020','640251010','640249040','640249030','640249020','640249010','640247040',
'640247030','640247020','640247010','640212040','640212030','640212010','640211040',
'640211030','640211020','640211010','640209040','640209030','640209020','640209010',
'640207040','640207030','640207020','640207010','640205040','640205030','640205020','640205010',
'640154040','640154030','640154010','640153040','640153030','640153020','640153010',
'640151040','640151030','640151020','640151010','640149040','640149030','640149020',
'640149010','640147040','640147030','640147020','640147010','640112040','640112030',
'640111040','640111030','640111020','640111010','640109040','640109030','640109020','640109010',
'640107040',
'640107030','640107020','640107010','640105040','640105030','640105020','640105010',
'640554030',
'640554040'
))
order by l.LOC



SELECT t.loc
     , left(t.loc,3) as Aisle
	 , substring(t.loc,4,3) as Bay
	 , Right(t.loc, 3) as [Level]
	 , left(t.loc,3) + '-'+ substring(t.loc,4,3) + '-' +Right(t.loc, 3) as [LocationNumber]
	 , CASE WHEN (convert(int, substring(t.loc,4,3)) % 2) = 0 THEN 'Even' ELSE 'Odd' END as EvenOdd
	 , t.CheckDigit AS CheckDigit
	 , left(t.loc,3) + '-'+ substring(t.loc,4,3) + '-' +Right(t.loc, 3) as [ReadableLoc]
	 --, left(t.loc,3) as Aisle
	 --, substring(t.loc,4,3) as Bay
	 --, Right(t.loc, 3) as [Level]
	 , lcd.[Circle]
	 , lcd.[Diamond]
	 , lcd.[Rectangle]
	 , lcd.[Square]
	 , lcd.[Triangle]
FROM #TempLCD t
left join [aero].[LocationCheckDigits] lcd
on t.CheckDigit = lcd.checkdigit

-- second query to determine missing locs vvvv
-- use create table as temp table for loc variable only with values of all locations
-- this results in only selecting locs that arent assigned a loc in wmwhse1
create table #temploc (
loc varchar(10))
insert into #temploc
values 
('640099010'),('640099020'),('640099030'),('640099040'),('640100030'),
('640100040'),('640101010'),('640101020'),('640101030'),('640101040'),('640102030'),('640102040'),
('640103010'),('640103020'),('640103030'),('640103040'),('640104030'),('640104040'),('640105010'),
('640105020'),('640105030'),('640105040'),('640106030'),('640106040'),('640107010'),('640107020'),
('640107030'),('640107040'),('640108030'),('640108040'),('640109010'),('640109020'),('640109030'),
('640109040'),('640110030'),('640110040'),('640111010'),('640111020'),('640111030'),('640111040'),
('640112030'),('640112040'),('640141010'),('640141020'),('640141030'),('640141040'),('640142010'),
('640142030'),('640142040'),('640143010'),('640143020'),('640143030'),('640143040'),('640144010'),
('640144030'),('640144040'),('640145010'),('640145020'),('640145030'),('640145040'),('640146010'),
('640146030'),('640146040'),('640147010'),('640147020'),('640147030'),('640147040'),('640148010'),
('640148030'),('640148040'),('640149010'),('640149020'),('640149030'),('640149040'),('640150010'),
('640150030'),('640150040'),('640151010'),('640151020'),('640151030'),('640151040'),('640152010'),
('640152030'),('640152040'),('640153010'),('640153020'),('640153030'),('640153040'),('640154010'),
('640154030'),('640154040'),('640199010'),('640199020'),('640199030'),('640199040'),('640200010'),
('640200030'),('640200040'),('640201010'),('640201020'),('640201030'),('640201040'),('640202010'),
('640202030'),('640202040'),('640203010'),('640203020'),('640203030'),('640203040'),('640204010'),
('640204030'),('640204040'),('640205010'),('640205020'),('640205030'),('640205040'),('640206010'),
('640206030'),('640206040'),('640207010'),('640207020'),('640207030'),('640207040'),('640208010'),
('640208030'),('640208040'),('640209010'),('640209020'),('640209030'),('640209040'),('640210010'),
('640210030'),('640210040'),('640211010'),('640211020'),('640211030'),('640211040'),('640212010'),
('640212030'),('640212040'),('640241010'),('640241020'),('640241030'),('640241040'),('640242010'),
('640242030'),('640242040'),('640243010'),('640243020'),('640243030'),('640243040'),('640244010'),
('640244030'),('640244040'),('640245010'),('640245020'),('640245030'),('640245040'),('640246010'),
('640246030'),('640246040'),('640247010'),('640247020'),('640247030'),('640247040'),('640248010'),
('640248030'),('640248040'),('640249010'),('640249020'),('640249030'),('640249040'),('640250010'),
('640250030'),('640250040'),('640251010'),('640251020'),('640251030'),('640251040'),('640252010'),
('640252030'),('640252040'),('640253010'),('640253020'),('640253030'),('640253040'),('640254010'),
('640254030'),('640254040'),('640299010'),('640299020'),('640299030'),('640299040'),('640300010'),
('640300030'),('640300040'),('640301010'),('640301020'),('640301030'),('640301040'),('640302010'),
('640302030'),('640302040'),('640303010'),('640303020'),('640303030'),('640303040'),('640304010'),
('640304030'),('640304040'),('640305010'),('640305020'),('640305030'),('640305040'),('640306010'),
('640306030'),('640306040'),('640307010'),('640307020'),('640307030'),('640307040'),('640308010'),
('640308030'),('640308040'),('640309010'),('640309020'),('640309030'),('640309040'),('640310010'),
('640310030'),('640310040'),('640311010'),('640311020'),('640311030'),('640311040'),('640312010'),
('640312030'),('640312040'),('640399010'),('640399020'),('640399030'),('640399040'),('640400010'),
('640400030'),('640400040'),('640401010'),('640401020'),('640401030'),('640401040'),('640402010'),
('640402030'),('640402040'),('640403010'),('640403020'),('640403030'),('640403040'),('640404010'),
('640404030'),('640404040'),('640405010'),('640405020'),('640405030'),('640405040'),('640406010'),
('640406030'),('640406040'),('640407010'),('640407020'),('640407030'),('640407040'),('640408010'),
('640408030'),('640408040'),('640409010'),('640409020'),('640409030'),('640409040'),('640410010'),
('640410030'),('640410040'),('640411010'),('640411020'),('640411030'),('640411040'),('640412010'),
('640412030'),('640412040'),('640441010'),('640441020'),('640441030'),('640441040'),('640442010'),
('640442030'),('640442040'),('640443010'),('640443020'),('640443030'),('640443040'),('640444010'),
('640444030'),('640444040'),('640445010'),('640445020'),('640445030'),('640445040'),('640446010'),
('640446030'),('640446040'),('640447010'),('640447020'),('640447030'),('640447040'),('640448010'),
('640448030'),('640448040'),('640449010'),('640449020'),('640449030'),('640449040'),('640450010'),
('640450030'),('640450040'),('640451010'),('640451020'),('640451030'),('640451040'),('640452010'),
('640452030'),('640452040'),('640453010'),('640453020'),('640453030'),('640453040'),('640454010'),
('640454030'),('640454040'),('640499010'),('640499020'),('640499030'),('640499040'),('640500010'),
('640500030'),('640500040'),('640501010'),('640501020'),('640501030'),('640501040'),('640502010'),
('640502030'),('640502040'),('640503010'),('640503020'),('640503030'),('640503040'),('640504010'),
('640504030'),('640504040'),('640505010'),('640505020'),('640505030'),('640505040'),('640506010'),
('640506030'),('640506040'),('640507010'),('640507020'),('640507030'),('640507040'),('640508010'),
('640508030'),('640508040'),('640509010'),('640509020'),('640509030'),('640509040'),('640510010'),
('640510030'),('640510040'),('640511010'),('640511020'),('640511030'),('640511040'),('640512010'),
('640512030'),('640512040'),('640541010'),('640541020'),('640541030'),('640541040'),('640542030'),
('640542040'),('640543010'),('640543020'),('640543030'),('640543040'),('640544030'),('640544040'),
('640545010'),('640545020'),('640545030'),('640545040'),('640546030'),('640546040'),('640547010'),
('640547020'),('640547030'),('640547040'),('640548030'),('640548040'),('640549010'),('640549020'),
('640549030'),('640549040'),('640550030'),('640550040'),('640551010'),('640551020'),('640551030'),
('640551040'),('640552030'),('640552040'),('640553010'),('640553020'),('640553030'),('640553040'),
('640554030'),
('640554040')

SELECT        t.LOC -- selects temploc v
FROM            wmwhse1.LOC AS l -- from infor locs vv
right join  #temploc as t on t.loc = l.loc
WHERE     
l.loc IS NULL -- where values we passed in are null meaning these locs dont exist yet
order by l.LOC

-- atp-13566 re done on 1/21/19
-- FUNCTION [wmwhse1].[calcLOCCheckDigit] could help with check digits as well?
-- i removed the rectangle and triangle from select above and it may not have worked as i intended 
-- the table was messed up somehow copying from UAT to prod using import export tool / app
-- select Server then server name then DBO for from destination
-- select same as above but this time for destination where we want the copied info to go to
-- for ms sql afssql01 and sqldu01\uat are on same server diff dbo. rest is self explanatory

-- copied these into excel sheet updated check digit atp -13566
/*loc		Aisle	Bay	Level	LocationNumber	EvenOdd	CheckDigit	ReadableLoc	Circle	Diamond	Square
075001010	075		001	010		075-001-010			Odd		C		075-001-010	655		117		525
075001020	075		001	020		075-001-020			Odd		M		075-001-020	939		280		654
075001030	075	001	030	075-001-030	Odd	X	075-001-030	776	349	193
075001040	075	001	040	075-001-040	Odd	7	075-001-040	709	582	280
075001050	075	001	050	075-001-050	Odd	F	075-001-050	363	045	764
075002010	075	002	010	075-002-010	Even	K	075-002-010	053	991	444
075002020	075	002	020	075-002-020	Even	U	075-002-020	223	690	853
075002030	075	002	030	075-002-030	Even	5	075-002-030	546	205	991
075002040	075	002	040	075-002-040	Even	D	075-002-040	590	666	906
075002050	075	002	050	075-002-050	Even	N	075-002-050	323	921	295
075003010	075	003	010	075-003-010	Odd	S	075-003-010	076	736	726
075003020	075	003	020	075-003-020	Odd	3	075-003-020	468	771	653
075003030	075	003	030	075-003-030	Odd	B	075-003-030	777	927	091
075003040	075	003	040	075-003-040	Odd	L	075-003-040	758	560	517
075003050	075	003	050	075-003-050	Odd	W	075-003-050	653	599	547
075004010	075	004	010	075-004-010	Even	1	075-004-010	628	346	223
075004020	075	004	020	075-004-020	Even	9	075-004-020	999	549	813
075004030	075	004	030	075-004-030	Even	H	075-004-030	692	357	164
075004040	075	004	040	075-004-040	Even	T	075-004-040	045	398	828
075004050	075	004	050	075-004-050	Even	4	075-004-050	748	300	776
075005010	075	005	010	075-005-010	Odd	7	075-005-010	709	582	280
075005020	075	005	020	075-005-020	Odd	F	075-005-020	363	045	764
075005030	075	005	030	075-005-030	Odd	R	075-005-030	667	159	433
075005040	075	005	040	075-005-040	Odd	2	075-005-040	513	528	357
075005050	075	005	050	075-005-050	Odd	A	075-005-050	943	523	250
075006010	075	006	010	075-006-010	Even	D	075-006-010	590	666	906
075006020	075	006	020	075-006-020	Even	N	075-006-020	323	921	295
075006030	075	006	030	075-006-030	Even	Y	075-006-030	991	616	946
075006040	075	006	040	075-006-040	Even	8	075-006-040	281	583	921
075006050	075	006	050	075-006-050	Even	G	075-006-050	928	223	976
075007010	075	007	010	075-007-010	Odd	L	075-007-010	758	560	517
075007020	075	007	020	075-007-020	Odd	W	075-007-020	653	599	547
075007030	075	007	030	075-007-030	Odd	6	075-007-030	044	027	560
075007040	075	007	040	075-007-040	Odd	E	075-007-040	519	076	824
075007050	075	007	050	075-007-050	Odd	P	075-007-050	927	153	218
075008010	075	008	010	075-008-010	Even	T	075-008-010	045	398	828
075008020	075	008	020	075-008-020	Even	4	075-008-020	748	300	776
075008030	075	008	030	075-008-030	Even	C	075-008-030	655	117	525
075008040	075	008	040	075-008-040	Even	M	075-008-040	939	280	654
075008050	075	008	050	075-008-050	Even	X	075-008-050	776	349	193
075009010	075	009	010	075-009-010	Odd	2	075-009-010	513	528	357
075009020	075	009	020	075-009-020	Odd	A	075-009-020	943	523	250
075009030	075	009	030	075-009-030	Odd	K	075-009-030	053	991	444
075009040	075	009	040	075-009-040	Odd	U	075-009-040	223	690	853
075009050	075	009	050	075-009-050	Odd	5	075-009-050	546	205	991
075010010	075	010	010	075-010-010	Even	B	075-010-010	777	927	091
075010020	075	010	020	075-010-020	Even	L	075-010-020	758	560	517
075010030	075	010	030	075-010-030	Even	W	075-010-030	653	599	547
075010040	075	010	040	075-010-040	Even	6	075-010-040	044	027	560
075010050	075	010	050	075-010-050	Even	E	075-010-050	519	076	824
075011010	075	011	010	075-011-010	Odd	H	075-011-010	692	357	164
075011020	075	011	020	075-011-020	Odd	T	075-011-020	045	398	828
075011030	075	011	030	075-011-030	Odd	4	075-011-030	748	300	776
075011040	075	011	040	075-011-040	Odd	C	075-011-040	655	117	525
075011050	075	011	050	075-011-050	Odd	M	075-011-050	939	280	654
075012010	075	012	010	075-012-010	Even	R	075-012-010	667	159	433
075012020	075	012	020	075-012-020	Even	2	075-012-020	513	528	357
075012030	075	012	030	075-012-030	Even	A	075-012-030	943	523	250
075012040	075	012	040	075-012-040	Even	K	075-012-040	053	991	444
075012050	075	012	050	075-012-050	Even	U	075-012-050	223	690	853
075013010	075	013	010	075-013-010	Odd	Y	075-013-010	991	616	946
075013020	075	013	020	075-013-020	Odd	8	075-013-020	281	583	921
075013030	075	013	030	075-013-030	Odd	G	075-013-030	928	223	976
075013040	075	013	040	075-013-040	Odd	S	075-013-040	076	736	726
075013050	075	013	050	075-013-050	Odd	3	075-013-050	468	771	653
075014010	075	014	010	075-014-010	Even	6	075-014-010	044	027	560
075014020	075	014	020	075-014-020	Even	E	075-014-020	519	076	824
075014030	075	014	030	075-014-030	Even	P	075-014-030	927	153	218
075014040	075	014	040	075-014-040	Even	1	075-014-040	628	346	223
075014050	075	014	050	075-014-050	Even	9	075-014-050	999	549	813
075015010	075	015	010	075-015-010	Odd	C	075-015-010	655	117	525
075015020	075	015	020	075-015-020	Odd	M	075-015-020	939	280	654
075015030	075	015	030	075-015-030	Odd	X	075-015-030	776	349	193
075015040	075	015	040	075-015-040	Odd	7	075-015-040	709	582	280
075015050	075	015	050	075-015-050	Odd	F	075-015-050	363	045	764
075016010	075	016	010	075-016-010	Even	K	075-016-010	053	991	444
075016020	075	016	020	075-016-020	Even	U	075-016-020	223	690	853
075016030	075	016	030	075-016-030	Even	5	075-016-030	546	205	991
075016040	075	016	040	075-016-040	Even	D	075-016-040	590	666	906
075016050	075	016	050	075-016-050	Even	N	075-016-050	323	921	295
*/

-- make note about the excel data population smart feature josh talks about
-- end of ticket atp-13155


/*							ATP-13184
							order with 2 lines missing 1

first went through sql using these queries to try and find order and
all the lines on the order when in nav and also in infor

select *
from wms_ORDERDETAIL
where EXTERNORDERKEY = 'FT0003856045'

select *
from wms_ORDERSTATUSHISTORY
where ORDERKEY = '0014649292'
order by ADDDATE

select *
from orders (nolock)
where primary_reference = 'FT0003856045'

select *
from Lineitem l(nolock)
where l.order_primary_reference = 'FT0003856045'

select *
from Lineitem_Backorders (nolock)
where orders_id = 37445360

select *
from Fulfillment_transaction(nolock)
where trans_key02 = 37445360
-- not the order id ? what is this 

after seeing strange stuff like orderstatushistory showing only 1 line as 0001
and line item saying 1 line as 0003

needed to find source
as this is 30 days old cant check boomi or api logs

so james informed me i could use WebSvc_Trans_Log table
queried this order and copied details into notepad ++
and confirmed only 1 line sent to us and this became billable


/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Trans_id]
      ,[Trans_time]
      ,[Trans_type]
      ,[Details]
  FROM [LEBANON].[dbo].[WebSvc_Trans_Log](nolock)
  where details like '%500522461-IN1%'
  and Trans_time > '10-13-2018'

-- end of atp-13184

-- 								atp-13186
-- ticket for matt ras stuck orders
-- feedback from infor on knowledge base
-- run this as SA login


SELECT
    r.session_id AS spid
        ,r.cpu_time,r.reads,r.writes,r.logical_reads 
        ,r.blocking_session_id AS BlockingSPID
        ,LEFT(OBJECT_NAME(st.objectid, st.dbid),50) AS ShortObjectName
        ,LEFT(DB_NAME(r.database_id),50) AS DatabaseName
        ,s.program_name
        ,s.login_name
        ,OBJECT_NAME(st.objectid, st.dbid) AS ObjectName
        ,SUBSTRING(st.text, (r.statement_start_offset/2)+1,( (CASE r.statement_end_offset
                                                                  WHEN -1 THEN DATALENGTH(st.text)
                                                                  ELSE r.statement_end_offset
                                                              END - r.statement_start_offset
                                                             )/2
                                                           ) + 1
                  ) AS SQLText
    FROM sys.dm_exec_requests                          r
        JOIN sys.dm_exec_sessions                      s ON r.session_id = s.session_id
        CROSS APPLY sys.dm_exec_sql_text (sql_handle) st

-- can use close orders to fix these also

/*Description:
There have been a couple of times now where the scheduled jobs of Event Monitor
 and Event Billing have been 'running' for hours.  There seems to be a problem when 
 both are running at the same time.
 
Resolution:
Fixed in Release: 1.0.2/1.0.3


Fix Type:  Database configuration change.

After researching the issues with the database, we have determined that in a SQL Server
 environment, the database isolation level should be set to Read Committed Snapshot. 
 The default isolation level when a database is created is Read Committed.   

To test:  Go to the Billing Workbench > Configuration > Recurring Rules > 
Inventory Dates UI screen and update some of the records. 
Run the Event Monitor and Event Billing jobs at the same time as the updates are happening.
  The inventory changes and jobs should complete correctly.

Changes:  update the database isolation level to read committed snapshot.
 Check with your database administration on how to do this.

Read committed snapshot uses row versioning to allow SQL statements to proceed based
 on a snapshot of committed data at the time the statement is issued.

First we need to turn on READ_COMMITTED_SNAPSHOT for our database.                     
          ALTERDATABASE TEST SET READ_COMMITTED_SNAPSHOT ON;

In order to execute this statement all connections to the database need to be closed.

To check that it has been enabled you can run the following SQL.  
select is_read_committed_snapshot_on from sys.databases where name = 'TEST'

*/

/* 						ticket atp-13140
[pr_Report_Commodity_Sheet] and [pr_Report_Inventory_Header]
used for how to accomplish this ticket
Liz wants header to pull lot info and qty like commodity is. commod using lotxlocxid
and header isnt

lot 08 doesnt match on web live version what sql shows. 
james helped find report options and save data checked which prevents live prod
data from being used

also added qty on hand



/*							ATP-12632
							Carrier codes are not populating correctly when they're
							 transferring from AERO to SAP.
 							Please us code FXHD for FedEx Home Delivery ID# 19011
							12/1/18 - 12/

using table OrderExporttoSAP 
and AFI_DropShipLineitem to try and find where we are sending FD04 instead of FXHD

looked at boomi job afi order export (SAP)
looked at mapping and nothing showing carrier 4 digit code
looked at sql view and nothing showing 4 digit code
james says this is likely on their end. maybe their system isnt used to seeing
the ship method id we send 19011 the way the mean it to.

following up with kelly to see what else we can do.

/*
							CI-163

more trouble with shelf life
-- might be able to use this

--update wms_orderdetail
set shelflife = -1
where EXTERNORDERKEY in ('RA0000038510', 'RA0000038512', 'RA0000038479')
and sku = '81502828'

or may have to update lot04 or 05 to set manufac date or change shelf life

--update l set l.lottable04 = '2018-01-01 06:00:00.000'
--select lottable04, * 
from [scprd].wmwhse1.lotattribute l
where SKU = '82440459'
and lot = '0000184744'

this works to update manufac date to something more recent. safe in UAT. 
need to remember or find the workaround for did not allocate. 
i believe this is also to do with lots / locs

turns out i just reset the alloc strat AND updated all the manufac dates for all
lots for SKU on this order and this worked. ONLY OKAY IN UAT

still need to fix DC# and vend # for UCC label
correct vend # to be hard coded 0489773783
-- end of CI-163


/*							ATP-13177
							Easy Button Function to allocate a wave 
							to the pick mod or z640
basically opened the easy button procs for CDL zone allocation and process cdl zone alloc
changed contents to AOS and created new procs for these 2 as AOS


script

std alloc strat 

look at 640 first
otherwise 201
location handling makes alloc go to zone a or 9
prefers A or alphanums

hard coded zones

locations for PM 
				 201 106 110



				 203 076 010


heres an example
USE [ENTERPRISE]
GO

/****** Object:  StoredProcedure [dbo].[easy_AOS_Zone_Allocation]    Script Date: 11/13/2018 1:53:09 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE     PROCEDURE [dbo].[easy_AOS_Zone_Allocation]
(
	@whseid char(3),
	@wavekey varchar(10),
	@zone nvarchar(50) 
)
AS
/*
	10/05/2017
	EASY BUTTON PROJECT
	Runs AOS Waving for Production Orders Stored Procedure
*/

/*
	Programmer:	Ben Yurchison	
	Create Date:	11/13/2018
	Description:	Runs AOS Waving for Production Orders Stored Procedure
	Date Modified:	
	Programmer:	

	Test:
	exec [easy_AOS_Zone_Allocation] 1,'0000320732',
*/
SET NOCOUNT ON

DECLARE @rtn_status int, @msg varchar(200)

IF @whseid = 'WH1'
	EXEC @rtn_status = LEBANON.dbo.pr_Process_AOS_Zone_Allocation @wavekey, @zone
ELSE IF @whseid = 'WH2'
	SET @rtn_status = 9
ELSE
	SET @rtn_status = 9

SELECT @msg = CASE @rtn_status
	WHEN 0 THEN ''
	WHEN 1 THEN 'Error: Wave not found or has no orders.'
	WHEN 9 THEN 'Error: Invalid Whseid'	--not likely
	ELSE 'Unknown'
	END

IF @msg<>''	
	RAISERROR(@msg,16,1)


GO

-- issue with above is that there was no control over location types for pick. need an updated
-- tool to make the picks location type change for locations 201 and 640 only but only one or the other
-- here is what james created for this 

CREATE PROCEDURE [dbo].[pr_Process_AOS_Allocation] --	'0000256613'
(
	
	@zone nvarchar(50) 
)
AS
SET NOCOUNT ON
--EXECUTE pr_Process_CDLWAVEZONEPRODORDERS '0000291067'
-- the updates made keep the location types set until the easy button is re used 
-- with the opposite zone.
-- first section states if zone is 201 we change loc type from other to pick
if @zone = '201'
Begin

update s set locationtype = 'PICK'
--select 'PICK', l.* 
from wms_SKUXLOC s 
where s.storerkey in ('AOS', 'RAS')
and s.loc like '201%'

-- then it changes zones 640 loc type from pick to other
update s set locationtype = 'OTHER'
--select 'OTHER', l.* 
from wms_SKUXLOC s 

where s.storerkey in ('AOS', 'RAS')
and s.loc like '640%'
end
if @zone  =  '640'
begin
-- second section does opposite - if loc 201 change from pick to other
update s set locationtype = 'OTHER'
--select 'OTHER', l.LOCATIONTYPE, s.*
from wms_SKUXLOC s 

where s.storerkey in ('AOS', 'RAS')
and s.loc like '201%'
-- and if loc 640 change from other to pick
update s set locationtype = 'PICK'
--select 'PICK',l.LOCATIONTYPE, l.* 
from wms_SKUXLOC s 

where s.storerkey in ('AOS', 'RAS')
and s.loc like '640%'
end

GO


-- end 13177


-- magic 
SELECT DISTINCT o.name AS Object_Name,o.type_desc
FROM sys.sql_modules m 
INNER JOIN sys.objects o 
ON m.object_id=o.object_id
WHERE m.definition Like '%event%'
--WHERE m.definition Like '%pds.fnTrim%'

-- v2 magic
SELECT Name
FROM sys.procedures
WHERE OBJECT_DEFINITION(OBJECT_ID) LIKE '%Inventory_Stop_Ship%'

/*							ATP-12776
							Document cause of CPG holds 
							
creating a word doc for filipe

going to look for tables that may have codes or desc that state transactions or
status' before it went to hold

then going to look for documentation or clues as to what else could cause holds

existing CPG stored procs may have some comments or useful info

queried through SQL to find hold information and came across holdtrn in scprd. as well as tons of
other tables, views and procs providing info

select *
from SCPRD.dbo.wmwhse2.holdtrn (nolock)

select id, *
from mason.dbo.wms_LOTXLOCXID
where [STATUS] = 'HOLD'

got in contact with Mason OPS Inventory team
from Adam:
-Manually requested by AE’s
-Put on hold by the system due to stop ship or being expired.
from Nick:

Kit builds from requests and spreadsheet
Following qty on hold for kit
Move screen – each item for kt build mv 150 from mo50 0101 to hmo50 0101 
Use LPN or OPH 111518
95% of the time its kit builds or product needed to build or kits on hold waiting for orders
5% quality or otherwise and returns
Return location which is a hold and a reason code

For report: On Hold details x SKU
On hold details by SKU 	0353 kit designation then date
Most of the non-sense ones are from a long time ago and can be ignored on this report

-- what are LPN 's? license plate numbers usually match caseid right?

-- this is generic info from querying procs and tables - total tables and views/procs that
possess info is almost 50
-v-v-v-v-v-vv-v-v-v-v-v-vv-v-v-vv-vv-
From stored proc – Report ONHOLD DETAILxSKU
Description will be either Stage, Return or Damage from the loc column in lotxlocxID  view
From stored proc – Report Mason Cpg Inventory on hold
Report pulls data to find holds from lotxlocxID, inventoryedit and inventory hold
Where qty isn’t 0 And loc not stage, return, damage, QC, TOINN and TOMason

A lot of information from views, tables and stored procs are leading to strange results but some simple ones as well.
A lot of holds are caused by expired items(not applicable for CPG) and occurs for both orders and items.
-^-^-^-^-^-^-^-^-^-^-^-^


*/

/*							ATP-13209
							We are unable to Dock confirm 13 orders


select *
from enterprise.dbo.aspnetusers u(nolock)
join enterprise.dbo.AspNetUserRoles r (nolock) on r.UserId = u.id
where u.email like '%ben%'
and u.Id = 'a8415c19-8626-4918-9295-9d4c3670b103'


select *
from enterprise.dbo.aspnetusers u(nolock)
join enterprise.dbo.AspNetUserRoles r (nolock) on r.UserId = u.id
where u.email like '%james%'
and u.Id = '0d8fdeaa-20fd-4e79-8bc3-7c771a7b1dc3'

after James suggested updating my role myself using tables in enterprise
was about to first see which id was mine and what role i needed to assign myself

then used edit top 200 rows under aspnetUserRoles table and pasted my Id and the Role ID

now hopefully i can test the SC portal properly for this ticket

sc portal tools arent solving issue

using sql to dig around more

took sku to get the item id to query fulfillment transaction
to then check  scprd.wmwhse1.log history for the times / dates where sku trans occurred
this confirmed that before change was made at 10am with PK wizard that
sku 80307322 was pk 3 pk but after it was 12pk

now need to find fix maybe with infor assistance and also

need to check other orders for different skus that could have same pack key problem

These orders that arent getting pack or shipped complete are consistently having no
Drop ID
orders with 80307322 sku causing an issue:
RA0000040726 OR 
RA0000040815 OR 
RA0000040775 OR
RA0000040749 OR
RA0000040816 OR
RA0000040796 OR
RA0000040765 OR
RA0000040772 OR
RA0000040734 OR
RA0000040809

different sku 80307318 -- pk didnt change but pl did, shouldnt be causing same issue as above
RA0000040769
RA0000040717

different sku 81545572 -- doesnt appear to be PK issue at all but i could be wrong, lottable validationkey
changed but not sure if that could cause this issue
RA0000040819

different sku 81550346 -- lottable validation key did change, not sure if that could be cause
RA0000040819
*/


/*							ATP-13262
							Ras- retransmit 945's for specific PO's

join is inner, dont use outter but more importantly dont use a join on ff-id
was trying to pull all records with that ff-id instead of trans_key01
not feasible when trying to find a short list of orders
also PO says customer reference in 945 get but was reference_4						

select *
from orders o (nolock)
join fulfillment_transaction f (nolock) on f.trans_key01 = o.orders_id and trans_submodule = 'SHIPPED'
where o.fulfillment_id = 1087
and o.reference_4 in (
'4239444',
'5490110',
'5490154',
'6877519',
'7342103')


--update f
set f.trans_status = 0
--select *
from orders o
join fulfillment_transaction f on f.trans_key01 = o.orders_id and trans_submodule = 'SHIPPED'
where o.fulfillment_id = 1087
and o.reference_4 in (
'4239444',
'5490110',
'5490154',
'6877519',
'7342103')

setting trans submodule to 0 tells system to resend to infor
same with trans_status from 9 to 0 this will say, "order is shipped lets try to ship again" this
will retrigger 945s

*/

/*							ATP-13269
							RF account is locked out

wc dc 1
active directory
type in wc-rf
go to account and then check box unlock

use screen shots to help document in confluence
unlocks so users can start using RF again

*/



/*							ATP-13193
							Ras orders stuck in part shipped

various reasons such as issue with needing to use close orders for stuff that is showing
part shipped but is fully shipped qty wise

basically since these are already out of the building and shipped these just need to be closed out
using close order under top actions.
however still could be a problem with sku 80307322 because when we try to pick just this line
it errors saying 0 lines will be picked even though this item is checked


/*							ATP-13140
							Inventory Header Report Not Updating in Navigator
							11/19/18 -

inventory_header proc and report need to be updated to include qtyonhand and to make
sure that they are properly displaying lot info							

looks like only lot and qty on hand will be available to update as this is a core report and
exp and SSD are too similar we need to make less redundant. may not make any changes in prod


/*							ATP-13289
							Ras Nordstrom ucc128 label fixes
							11/19/18 -

need to update ucc128 arc ltl proc and corresponding crystal report

add and remove leading zeros

best example i have and tested it worked is- right ('0'+convert(varchar, ff.flexfield18),4) as 'DC'
to put a 0 in front of 3 digits.

trying to practice taking from proc a where and from clause with my select of a convert w/ leading 0s

select right ('0'+convert(varchar, ff.flexfield18),4) as 'DC',
	ff.*
from Orders o with (nolock) 
	JOIN Orders_Flexfields ff with (nolock) ON o.orders_id = ff.orders_id
	join wms_orders_all wo with (nolock) on wo.externorderkey = o.primary_reference
	join wms_PICKDETAIL pd (nolock) on pd.ORDERKEY = wo.ORDERKEY
where pd.WAVEKEY = '0000256819'

update used for carrier code field ff25

--UPDATE ox SET flexfield25 = case 
			when o.ship_method_id = 19010 then 'FEDEX GROUND' 
			when o.ship_method_id = 11008 then 'FEDEX 2-DAY' 
			else s.[description] end

--select * 
	FROM LEBANON.dbo.Orders o(nolock)
		JOIN LEBANON.dbo.Orders_Flexfields ox(nolock) ON o.orders_id = ox.orders_id
		JOIN lebanon.dbo.Ship_Method s (nolock) on s.ship_method_id = o.ship_method_id
	where o.fulfillment_id = 1087
	and o.primary_reference = 'RA0000015763'
	and o.customer_reference = 'ORD0000525'

query to find bol and PROnumber
select * 
	FROM LEBANON.dbo.Orders o(nolock)
		JOIN LEBANON.dbo.Orders_Flexfields ox(nolock) ON o.orders_id = ox.orders_id
		JOIN lebanon.dbo.Ship_Method s (nolock) on s.ship_method_id = o.ship_method_id
		left join lebanon.dbo.wms_pickdetail pd (nolock) on pd.orderkey = o.orders_id
		left join lebanon.dbo.wms_LTLShipmentPallet wlp with (nolock) on wlp.PalletKey = pd.DROPID
		left join scprd.wmwhse1.LTLShipment wls with (nolock) on wls.ShipmentKey = wlp.ShipmentKey
	where o.fulfillment_id = 1087
	and o.primary_reference = 'RA0000015763'
	and o.customer_reference = 'ORD0000525'


this query worked to find order

	SELECT o.orders_id, b.external_batch_id, o.add_date
FROM LEBANON.dbo.Orders o(nolock)
	JOIN LEBANON.dbo.Orders_Batch ob with (nolock) ON o.orders_id = ob.orders_id
	JOIN LEBANON.dbo.Batch b(nolock) ON ob.batch_id = b.batch_id
WHERE o.fulfillment_id = 1087
 and b.external_batch_id like 'RAS-%'
 -- and o.primary_reference = 'RA0000015763'

 new orders come in on API with auto gen RAS-123456 format
 was a bug with edi 940 post process using 'EDI940%' still

 case when o.consign like '%Nordstrom%' then right ('0'+convert(varchar, ff.flexfield17),4) 
		else convert(varchar, ff.flexfield17)end as 'Store',		
		-- case for nord add lead 0 for store else other stores no lead 0
-- this worked for store and DC

/*							ATP-13243
							Ras unable to dock confirm this order
							11/20/18 - 11/20
0000185258 lot with shelf life issue on 13243
another dock conf issue but this seemed to be resolved by infor possibly as i was able to 
dock conf on my own. but had same issue with sku 

verified the infor error of shelflife wasnt valid as lot above with item 81345310
was able to close order / ship order 

/*							ATP-13307
							Please ship complete VA0000035690 it is stuck or missing serial capt
							11/20/18 - 11/20

this is already shipped complete VA0000035690
but this is a reminder ticket to fix my stored proc in UAT and prod to make sure this can be used
as an easy button in the future

--lane1312B


/*							ATP-13229
							following case ids showing 0 picked in pd and not started in order det
							11/20/18 - 11/20

ras orders needing ship label after being corrected		Ras orders with sku issue on other ticket
RA0000040730											RA0000040726
RA0000040718											RA0000040815
RA0000040732											RA0000040775
RA0000040738											RA0000040749
RA0000040741											RA0000040816
RA0000040763											RA0000040796
RA0000040759											RA0000040765
RA0000040752											RA0000040772
RA0000040753											RA0000040734
RA0000040753											RA0000040809
RA0000040782											
RA0000040769											
RA0000040778											
RA0000040778											
RA0000040804											
RA0000040794											
RA0000040810											
RA0000040803											
RA0000040816											


possible skus with issues possibly shelf life or other
81360331
82440440 x6
81579187 x3
81602887 x4
82440436

1642 is SL for sku 82440436

RA0000040752 is shipped complete and need to double check if this has an issue at all

need to fix picks for these orders. showing different statuses in pick detail and orders

STATUS	STATUS	SERIALKEY	WHSEID	ORDERKEY	STORERKEY	EXTERNORDERKEY
61		09		8576129		WH1		0014762473	RAS			RA0000040730
61		09		8576113		WH1		0014762457	RAS			RA0000040718
61		09		8576132		WH1		0014762476	RAS			RA0000040732
61		09		8576136		WH1		0014762480	RAS			RA0000040738
61		09		8576139		WH1		0014762483	RAS			RA0000040741
92		09		8576162		WH1		0014762506	RAS			RA0000040763
61		09		8576163		WH1		0014762507	RAS			RA0000040759
61		09		8576182		WH1		0014762526	RAS			RA0000040782
92		09		8576169		WH1		0014762513	RAS			RA0000040769
92		09		8576178		WH1		0014762522	RAS			RA0000040778
92		09		8576178		WH1		0014762522	RAS			RA0000040778
92		09		8576178		WH1		0014762522	RAS			RA0000040778
92		09		8576178		WH1		0014762522	RAS			RA0000040778
61		09		8576206		WH1		0014762550	RAS			RA0000040804
61		09		8576194		WH1		0014762538	RAS			RA0000040794
61		09		8576212		WH1		0014762556	RAS			RA0000040810
61		09		8576199		WH1		0014762543	RAS			RA0000040803
61		09		8576217		WH1		0014762561	RAS			RA0000040816


query used for above

 select WO.STATUS,
		OD.STATUS,
		CASEID,
		od.ORIGINALQTY,
		od.openqty,
		od.QTYALLOCATED,
		od.QTYPICKED,
		od.sku,
		pd.lot,
		wo.EXTERNORDERKEY,
		od.ORDERKEY
 from wms_ORDERS wo (nolock)
 join wms_PICKDETAIL pd (nolock) on pd.orderkey = wo.orderkey
 join wms_ORDERDETAIL od (nolock) on od.ORDERKEY = wo.ORDERKEY
 where CASEID in ('0071027100',
 '0070971497',
 '0071011117',
 '0071010600',
 '0071027103',
 '0070971499',
 '0070971500',
 '0071010518',
 '0071027101',
 '0070971498',
 '0071010599',
 '0071027102',
 '0071010602',
 '0071010603',
 '0071011119',
 '0071011118',
 '0071027099',
 '0071010601')
 AND OD.OPENQTY <> 0
 AND OD.[STATUS] = 09
 order by od.sku

tested this query from james for some skus to verify it wasnt exp date or shelflife
 select la.lottable04 + 1642, la.lottable05 - 1642
, * From wms_lot l 
inner join wms_lotattribute la 
on la.lot = l.lot
join wms_ORDERDETAIL od on od.SKU = l.sku
where l.sku = '82440436' and l.qty > 0

in infor the pick detail for the skus we are having issues with james explained
that since there are 2 records and 2 dif caseids but 1 has drop ID other doesnt
because someone tried to ZERO ship and failed

emailed tracy and matt to see how they want these dealt with

according to james and josh i should be able to do an update to set qty picked on order & pick detail
to the same thing and then itll be able to be shipped.

so i need to figure out if my join above for this query will let me do the necessary update
because i know this join works
but is it enough?

these tables/views give me the right amount of info to update i believe. but will a simple update
upset the balance or effect other pieces in place? test something of this nature in UAT?

wms_ORDERS 
wms_PICKDETAIL 
wms_ORDERDETAIL

doing updates in DB to set orders to pickable status and then should be shipped in infor
deleting dupe or 2nd record of pick detail in infor before doing any of these updates


 --update od
 set [status] = 55,
	qtypicked = originalqty
-- select od.orderkey, od.sku, od.openqty, od.qtypicked, od.originalqty, pd.*
 from scprd.wmwhse1.ORDERDETAIL od
 join scprd.wmwhse1.pickdetail pd on pd.orderkey = od.orderkey and pd.sku = od.sku
 where od.externorderkey = 'RA0000040730'
 --and od.[status] < 68
 and od.sku = '82440436'

 AND 
 --update scprd.wmwhse1.PICKDETAIL
 set id = '',
 loc = fromloc,
 qty = 40,
  [status] = 5
 where CASEID = '0070956266'
 and sku = '82440436'
 and pickdetailkey = '0061490808'

then run store proc fix allocations



/*							ATP-13374
							Ship confirms for N182950Z0K file
							11/27/18 - 11/27/18
-- queries for finding orders from the file attached to ticket 
-- all these orders are cust ref #s
-- 
 select *
 from orders (nolock)
 where	customer_reference = '1829500108747'
 -- primary_reference = 'TK0001117009'

 select *
 from orders o (nolock)
 join Fulfillment_Transaction ft (nolock) on ft.trans_key01 = o.orders_id
 where o.fulfillment_id = 1145
 and ft.trans_submodule <> 'SHIPPED'
 and ft.trans_submodule = 'ACTIVE'
 and o.order_status = 'ALLOCATED'
 and customer_reference in ('1829500084317',
'1829500078701',		
'1829500079494','1829500079736',		
'1829500080850','1829500081750','1829500083954',		
'1829500084047','1829500084316','1829500084317','1829500085753','1829500086211',		
'1829500088720','1829500090334','1829500090494','1829500090592','1829500090915',
'1829500092687','1829500093001','1829500093512','1829500093735','1829500094714',
'1829500094816','1829500094819','1829500094821','1829500096507','1829500097082','1829500097270',		
'1829500097499','1829500098244','1829500098258','1829500098463','1829500098668',	
'1829500099567','1829500099648','1829500099878','1829500100152','1829500100194',		
'1829500100729','1829500101098','1829500101217','1829500101497','1829500101549',
'1829500101550','1829500101551','1829500101552','1829500101553','1829500101554',
'1829500101555','1829500101556','1829500101557','1829500101558','1829500101559',
'1829500101560','1829500101561','1829500101562','1829500101563','1829500101564',
'1829500101565','1829500101566','1829500101567','1829500101568','1829500101569',
'1829500101570','1829500101571','1829500101572','1829500101573','1829500101574',
'1829500101575','1829500101576','1829500101577','1829500101578','1829500101579',
'1829500101580','1829500101581','1829500101582','1829500101583','1829500101584',
'1829500101585','1829500101586','1829500101587','1829500101588','1829500101589',
'1829500101590','1829500101591','1829500101592','1829500101593','1829500101594',
'1829500101595','1829500101596','1829500101597','1829500101598','1829500101599',
'1829500101600','1829500101601','1829500101602','1829500101603','1829500101604',
'1829500101605','1829500101606','1829500101607','1829500101608','1829500101609',
'1829500101610','1829500101611','1829500101612','1829500101613','1829500101614',
'1829500101615','1829500101616','1829500101617','1829500101618','1829500101619',
'1829500101620','1829500101621','1829500101622','1829500101623','1829500101624',
'1829500101625','1829500101626','1829500101627','1829500101628','1829500101629',
'1829500101630','1829500101631','1829500101632','1829500101633','1829500101634',
'1829500101635','1829500101636','1829500101637','1829500101638','1829500101639',
'1829500101640','1829500101641','1829500101642','1829500101643','1829500101644',
'1829500101645','1829500101646','1829500101647','1829500101648','1829500101649',
'1829500101650','1829500101651','1829500101652','1829500101653','1829500101654',
'1829500101655','1829500101656','1829500101657','1829500101658','1829500101659',
'1829500101660','1829500101661','1829500101662','1829500101663','1829500101664',
'1829500101665','1829500101666','1829500101667','1829500101668','1829500101669',
'1829500101671','1829500101672','1829500101673','1829500101674','1829500101675',
'1829500101677','1829500101678','1829500101679','1829500101680','1829500101681',
'1829500101682','1829500101683','1829500101684','1829500101685','1829500101686',
'1829500101687','1829500101688','1829500101689','1829500101690','1829500101691',
'1829500101692','1829500101693','1829500101694','1829500101695','1829500101696',
'1829500101697','1829500101698','1829500101699','1829500101700','1829500101701',
'1829500101702','1829500101703','1829500101704','1829500101705','1829500101706',
'1829500101707','1829500101708','1829500101709','1829500101710','1829500101711','1829500101712','1829500101713',
'1829500101714','1829500101715','1829500101716','1829500101717','1829500101718',
'1829500101719','1829500101720','1829500101721','1829500101722',
'1829500101723','1829500101724','1829500101725','1829500101726','1829500101727',
'1829500101728','1829500101729','1829500101730','1829500101731','1829500101732',
'1829500101733','1829500101734','1829500101735','1829500101736','1829500101737',
'1829500101738','1829500101739','1829500101740','1829500101741','1829500101742',
'1829500101743','1829500101744','1829500101745','1829500101746','1829500101747',
'1829500101748','1829500101749','1829500101750','1829500101751','1829500101752',
'1829500101753','1829500101754','1829500101755','1829500101756','1829500101757',
'1829500101759','1829500101760','1829500101761','1829500101762','1829500101763',
'1829500101764','1829500101765','1829500101766','1829500101767','1829500101768',
'1829500101769','1829500101770','1829500101771','1829500101772','1829500101773',
'1829500101774','1829500101775','1829500101776','1829500101777','1829500101778',
'1829500101779','1829500101780','1829500101781','1829500101782','1829500101783',
'1829500101784','1829500101785','1829500102039','1829500102565','1829500102641',
'1829500103274','1829500103582','1829500103740','1829500104838','1829500105363',
'1829500105728','1829500105729','1829500106676','1829500107084','1829500107089',
'1829500107540','1829500107579','1829500107600','1829500107712','1829500107728',
'1829500108007','1829500108084','1829500108087','1829500108088','1829500108089',
'1829500108090','1829500108091','1829500108092','1829500108093','1829500108094',
'1829500108096','1829500108097','1829500108098','1829500108099','1829500108100',
'1829500108101','1829500108102','1829500108103','1829500108104','1829500108105',
'1829500108106','1829500108107','1829500108108','1829500108109','1829500108110',
'1829500108111','1829500108112','1829500108113','1829500108114','1829500108115',
'1829500108116','1829500108117','1829500108118','1829500108119','1829500108120',
'1829500108121','1829500108122','1829500108123','1829500108124','1829500108125',
'1829500108126','1829500108127','1829500108128','1829500108129','1829500108130',
'1829500108131','1829500108132','1829500108133','1829500108134','1829500108135',
'1829500108136','1829500108137','1829500108138','1829500108139','1829500108140',
'1829500108141','1829500108142','1829500108143','1829500108144','1829500108145',
'1829500108146','1829500108147','1829500108148','1829500108149','1829500108150',
'1829500108151','1829500108152','1829500108153','1829500108154','1829500108155',
'1829500108156','1829500108418','1829500108486','1829500108660','1829500108683',
'1829500108684','1829500108685','1829500108686','1829500108687','1829500108688',
'1829500108689','1829500108690','1829500108691','1829500108692','1829500108693',
'1829500108694','1829500108695','1829500108696','1829500108697','1829500108698',
'1829500108699','1829500108700','1829500108701','1829500108702','1829500108703',
'1829500108704','1829500108705','1829500108706','1829500108707','1829500108708',
'1829500108709','1829500108710','1829500108711','1829500108712','1829500108713',
'1829500108714','1829500108715','1829500108716','1829500108717','1829500108718',
'1829500108719','1829500108720','1829500108721','1829500108722','1829500108723',
'1829500108724','1829500108725','1829500108726','1829500108727','1829500108728',
'1829500108729','1829500108730','1829500108731','1829500108732','1829500108733',
'1829500108734','1829500108735','1829500108736','1829500108737','1829500108738',
'1829500108739','1829500108740','1829500108741','1829500108742','1829500108743','1829500108744','1829500108745',
'1829500108746','1829500108747','1829500108748','1829500108989','1829500109017','1829500109078',
'1829500109079','1829500109080','1829500109081','1829500109082','1829500109083','1829500109141',
'1829500109149','1829500109793',
'1829500109798','1829500111428','1829500111717','1829500112108','1829500112621',
'1829500112896','1829500113367',
'1829500113406')

 order by add_date desc
 
 select *
 from Fulfillment_Transaction (nolock)
 where trans_key01 = '37556136'
-- below is from a ship confirm and used to find and match with above cust ref
-- BCP1832000001129CA26              002000Y183300000000B41990983146026623680          18320070516

-- in summary 376 were shipped 76 still in allocated status and
-- some definitely ship confirmed but didnt find all


/*							ATP-13371
							Ras waves to be fixed and shipped
							11/27/18 - 11/28/18
-- team found fix for most of these orders because a sku level vs
-- order level change on pack key
-- When OPS updated the pack key through the pack key wizard, they didn't 
-- update the pack key on the lot	**** ROOT CAUSE ****					
-- ticket atp-13371 

wave 321754
RA0000041850 OR 
RA0000041847 or 
RA0000041841 or 
RA0000041839 or 
RA0000041831 or 
RA0000041804 or 
RA0000041793 or 
RA0000041781 or 
RA0000041772 or 
RA0000041784 or 
RA0000041762 or 
RA0000041763 or 
RA0000041747

with sku 81579187:
RA0000041747
RA0000041841
RA0000041839
RA0000041847
-- must wait for michael to put inv into these locs before we can run fix 
-- alloc and ship


/*							ATP-13402
							322208 ras wave 
							11/28/18 - 11/29/18
new ticket
-- container history barcode with case ids find some waves ----champ archive
-- see if it went down fill and seal
-- CASEID is barcode


RA0000041968 or
RA0000041967 or
RA0000041966 or
RA0000041965 or
RA0000041964 or
RA0000041963

by all these caseids - dropids
c.Barcode in ('0071211889',
'0071211888',
'0071211887',
'0071211886',
'0071211885',
'0071211884',
'0071211883',
'0071211882',
'0071211881',
'0071211880',
'0071211879',
'0071211878',
'0071211877',
'0071211876',
'0071211875',
'0071211874',
'0071211873',
'0071211872',
'0071211871',
'0071211870',
'0071211869',
'0071211868',
'0071211867',
'0071211866',
'0071211865')

nothing showing up for above in champ or champ_arc
however seeing lots of recent ras orders going to fill and seal before ship
appears that ops is doing this?

ticket wants all these updated to one id 0071211865
not sure josh will allow


/*							ATP-13268
							estimate removal of paperbecause.com from
							domtar pick ticket 
							11/29/18 - 11/29/18

-- wave 0000324159 or 0000327948 or 0000327915
remove paperbecause from pick ticket

easy

/*							ATP-13417
							following orders acknowledged by aero 11/24 not in
							nav? OOO797691 OOS812328
							11/29/18 - 11/29/18

total of 10 cust refs?							
just had to re run 5-6 docs in boomi.


/*							ATP-13290
							IRD moving from prov to FF update license
							in tms /dms test and then move to prod
							11/29/18 - 12/13/18
notes in confluence how to for CLS

hard code new addy in  [wmwhse1].[pr_AERO_TMS_INTERFACE]  


/*							ATP-13417
							order didnt send alert when cancelled
							for KET KB0000148330
							11/28/18 -

checked 940 process in boomi and doesnt look related after querying fulfillment
trans and seeing that order made it to allocated and active status
then was cancelled and proc doesnt do anything with already imported orders

james informed me of easy button log and used this to find who cancelled it

select *
from enterprise.dbo.EasyButtonLog (nolock)
where processname like '%cancel active%'
and paramval2 = 'KB0000148330'


/*							ATP-13452
							0014874628 pending picks
							per josh get w/ infor on cause of pending picks
							11/29/18 - 12/10/18

opened ticket but this order doesnt appear to have pending picks. did matt force
into another status already or something?
per josh check pick detail and shippick detail

james says this is likely in taskdetail, i may have misheard from josh?

-- used  to gather general info from order in these areas
select *
from lebanon.dbo.orders o (nolock)
join lebanon.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
join scprd.wmwhse1.PICKDETAIL pd (nolock) on pd.ORDERKEY = w.ORDERKEY
where o.primary_reference = 'AS0000298684'

-- used for findind where something may have gone wrong in tasks in statusmsg
select *
from wms_TASKDETAIL (nolock)
where caseid = '0071259084'
order by STARTTIME desc

/*							ATP-13223
							transaction sent unexpectedly
							fw damaged trans
							11/28/18 - 12/14/18

appears that my queries were mostly in vain. james helped with this one

select *
from wms_itrn_all (nolock)
where STORERKEY = 'FW'
and trantype = 'MV'
and EFFECTIVEDATE between '2018-10-13 03:25:56.000' and '2018-10-13 04:25:56.000'
order by EFFECTIVEDATE desc

according to boomi proc - Aero infor inventory move to damage
using view [wmwhse1].[vw_MoveToDamage] 

this, james surmised, says the nightly process picked up the FW items
when i shouldnt have at almost 330 am
need to find why it may have incorrectly had these items in damage or if
maybe the items went out and back in without the qty's being reset?

-- query to find only this list of skus in itrn where they are going to dmg loc
-- during the date range
select *
from wms_itrn_all (nolock)
where STORERKEY = 'FW'
and trantype = 'MV'
and toloc = 'DAMAGE'
and EFFECTIVEDATE between '2018-9-13 03:25:56.000' and '2018-10-13 04:25:56.000'
and sku in ('R1716','R3137','32131','R3916','T8452','T6230','S5302','R4238','S6791','T4033','32741','S9144','09BD05','13BD05','13BD06','R4571','R5005','R3136','R4441','V6469',
'R5162','T3610','R2056','R1984','S4228','R1985','T3885','T5945','U6497','U4100','S7982','08BD10','R3417','R4952','R2634','S5307','S7756','R1225','R4572','R1226','R4237','S3149','R3416','R4439','33465','Y3380','T8812','R0815','R5161','17CR01',
'T0004','R3135','T6421','S6468','S6792','17KN05','15CR07','17CR04','Z9186','U2633','16JM05','R1714','T3611','17KN01','S4100','R4954','10WV01','S6291','R0814','15QM06','R2335','T5944','T7181','S5856','16CR09','16KN14','13KN14','T4323','16JM07',
'S8737','T2655','16KN10','R0068','R4953','T8255','W1803','T5080','T5943','16CR06','33400','T4198','S3158','S3420','T3694','T4975','16SP01','30220','16KN06','R0820','R4132','U3041','T2652','T7179','U2958','T1353','T3822','R0175','16CR12',
'U1466','U1956','T1865','T6146','16WV01','16CR11','Z6424','U0183','16KN01','16KN09','S3159','32327','33058','U1065','U5872','T2131','T5659','T6956','S9150','Z9316','U3803','U9459','T0883','T1872','T2654','16KN03','R1229','R5004','AOMF','T0491',
'T4986','T5829','T6232','T6233','T6854','16JM06','16MM02','R0811','R6260','Z1818','Z3838','U7870','15CR05','T5459','16KN07','T8751','S7755','16WV03','R1412','Y0635','U8565','T1354','15KN04','15KN02','T2545','T2893','T4095','T9085','R6958','30872',
'31995','33483','Z2911','Z2922','Y0776','W1990','V7636','U2267','U2634','U3158','U3161','U5669','U7579','U7633','U7716','T0395','14CR04','T4652','T5476','T5933','T6231','S6574','SCWD','33252','Z1059','Z2991','W6013','U1948','U9383','T1792',
'T1793','T3615','T5079','T6438','T8449','S0475','S4098','31615','Z0163','Z0763','Z1084','Z1441','Z7615','Z8907','Y0052','Y1760','W6552','V6637','V6715','V8200','08WV03','10KN23','15WV01','15KN11','T3926','15BS01','15JM07','15KN13','16CR01',
'T9084','S3425','R3418','R4310','R4686','30753','31592','31764','31770','33208','33397','Z0412','Z2523','Z5816','U2929','10KN25','10SW02','6081','13KN13','12CR11','U4567','14NW01','U6487','U8352','14BD05','U9370','14BD12','15KN03','15SW01','15CR03',
'T2368','T2373','T2548','T2668','15KN08','T4983','15QM09','16BD04','16JM04','S5301','16CR07','16KN13','S8138','S9147','16CR10','17KN02','R0821','R1218','R1227','R1723','R1722','R1991','R2638','R2667','R3249','R4137','R5755','R5830','R7730')
order by EFFECTIVEDATE desc


/*							ATP-12969
							questions regarding CPG order turn time and
							report data and qualifiers
							11/15/18 - 12/13/18

research different procs for the reports in question

Order data pulled from where?

- orders o (nolock)
inner join 
	fulfillment_transaction ft (nolock)
		on o.orders_id = ft.trans_key01
left join	--9/11/2014 added per CMR 20140829.001 (ed-man)
	(select wo.externorderkey, tasks=count(*)
		from wms_orders wo(nolock)
		inner join wms_pickdetail pd(nolock)
			on wo.orderkey = pd.orderkey
		where pd.qty > 0 and pd.status='9'
		group by wo.externorderkey
		) td
		on o.primary_reference = td.externorderkey
where 
	(o.fulfillment_id = @fulfillment_id or o.fulfillment_id = @fulfillment_id2)
	--o.fulfillment_id = @fulfillment_id
	and ft.trans_module = 'ORDERS'
	--8/30/2006 To handle future drop_date orders
	and ft.trans_submodule = 'ALLOCATED'
	--and ft.trans_submodule = 'ACTIVE'
	and order_status = 'SHIPPED'
	and isnull(ship_date,'') <> ''
	and ft.trans_date between @startdate and @enddate
	and order_type not in ('PRODUCTION','SAVEDCART','SCRAP')

Order captured by day ordered or approved?

- type not in prod savedcart or scrap. trans sub allocated. pd status 9

Order volume include all order types, batch, backorder, standard, LTL?

- type not in prod savedcart or scrap

Shipped date captured if the order is part shipped or when order is shipped complete?

- actual ship date is only captured if status is 95 shipped complete
- still reports scheduled ship date earliest ship and earliest deliv dates

What hour is the cutoff for day for order to show as coming in that day?



Is there a "Ship" cutoff time used? Any shipments made after X time show as next day?
Does report 2421 capture both CPG and PDP?

- 
- depends on ship method of PDP will verify but not seeing when i run proc for PDP
- not seeing PDP at all even if i remove the ship method in where clause
possible bug with capitalization 'All' or 'ALL' both used in same proc

/*							ATP-13461
							ras ASN's missing
							11/29/18 - 12/13/18

not trying to retrigger
research results of ones that arent 9's in fulfillment trans

havent sent yet and should go out on next scheduled process if these arent stuck orders
RA0000041272
RA0000041257
RA0000041251
-- above dont appear stuck but will look further

havent shipped yet:
RA0000040800
RA0000041433

all the rest have sent


-- RA0000041433 only shows errored not pend subm or anything else
-- RA0000040800 stuck in allocated?

-- wave 0000321402 of 3 orders that jenny and tracy changed
-- looks like the Carrier name was incorrectly changed to 19010 instead of
-- fedex ground.
-- use dmsserver dbo.packages and dbo.shipments to see if data was created
-- for these orders and if not then no manifest was made
-- when creating /inserting into manifest follow current rules and what james 
-- said tracking = 'no tracking' or ' '?. caseid

/*							ATP-13471
							incorrect ship from addy on ras UCC128
							12/5/18 - 12/7/18

labels using ras are 
UCC128WaveRASLabelsZebra_With_ShipLabel.rpt
UCC128WaveRASLabelsZebra.rpt

ras zebra is fine
ras zebra with ship label has pg name in ship from formula




/*							ATP-13115
							the cost center for afi web order
							is on order FI0000158011
							verify if aero was to provide or customer
							11/1/18 - 

customer didnt put this on file we imported. it is a drop ship
order that didnt have all the required info.


select *
from Fulfillment_Transaction f(nolock)
join orders o (nolock) on o.orders_id = f.trans_key01
where o.primary_reference = 'FI0000158011'
order by trans_date desc

looked up process in boomi with james to confirm - james was incorrect about
boomi process it wasnt xml order import it was afi web cart order i believe 

-- just kidding james showed me with these queries why this order was 
-- imported using the original import we found for XML


select *
from orders_batch (nolock)
where orders_id = '36190234'

select *
from batch (nolock)
where batch_id = '1854038'
-- issue should be on AFI's end



/*							TIT-2
							Standup
							12/5/18

-- 12/5/18 issues with jeffnet and reports running from 12-5 am 
-- lots of ras issues that josh is going to assign and we track on log
-- i need to track API changes for transaction sent unexpectedly
-- make test orders in UAT for IRD move
-- old freight manager works better and james will develop for billing?


-- notes from james on process of wms
-- dock confirm will take picked complete to packed complete
-- once packed complete they can release
-- once released they can part ship
-- part shipped can send EDI ship conf
-- because some of the orders have multiple pick details stuck in 
-- pick complete it wont dock confirm or release etc..
-- if there are any orders or picks that arent dock conf and packed complete
-- the boomi process wont run to release which allows the part ship/ ship conf


-- pop up ras issue
-- troubleshooting help query
used these queries to find wave info for status and why they arent complete
	--322477
	-- 322465
select *
from wms_wavedetail wd (nolock)
join wms_orders o (nolock) on o.ORDERKEY = wd.ORDERKEY
join wms_PICKDETAIL pd (nolock) on pd.ORDERKEY = o.ORDERKEY
where wd.WAVEKEY like '%322465'
and o.STORERKEY = 'RAS'

select *
from wms_transmitlog tl
join wms_orders wo on tl.key1 = wo.orderkey
join wms_wavedetail wd on wd.ORDERKEY = wo.ORDERKEY
where tl.tablename = 'shipmentdockconfirm' --and tl.key2 = 'WAVE'
and wd.WAVEKEY like '%322465'
and KEY1 = '0014883464'
-- order 0014883382 -- case 0071250238
-- used barcode / caseid in champ arc server / dbo container history
-- after looking at champ online and not finding anything there.
-- searched dmsserver.packages with SUID and caseid(shipper pack ref)
-- james explained why the picks and ids werent = to the total needed
-- to have a packed complete

S:\PMO\2017 Implementations\Fairfield Warehouse Automation -- champ documentation
#?
#champ

/*							ATP-13472
							Missing caseid
							12/5/18 - 12/7/18

find the caseid! 0071243484
searched the champ arc and found data that it was assigned to induct
lane 16 and then diverted to lane 16 on 11/29 at 1:15pm

next searched orderdet and pick detail by caseid in sql
heres the order prim ref RA0000042242 part shipped wave 0000322464
12 lines 5 shipped 7 in pack complete
what needs to be done on IT end?
shipped lines dont show dropid in infor.
packed lines do. were the shipped lines force shipped in ops or?
why are some skus getting different caseids on different pickdetails?

task detail shows status 9 
EDITDATE
2018-11-29 13:06:49.000

looks like this pick was deleted in system and then reentered with new caseid?
somehow explains why customer has it but its not in manifest since
we shipped before the whole order was shipped complete
-- per josh probably wasnt deleted but backed out of wave even though
system thinks it went to shipping and was physically shipped??

james says this is due to ops oops creating multiple shipments
all diff caseids
472839506380 not foundfed 
472839506313
472839506368 not found fed 
472839506276
472839506254
472839506302
472839506298
472839506390 not found fed 
472839506324
472839506357 not found fed
472839506265
472839506335
472839506379 not found fed
472839506346
472839506405 not found fed
472839506287

had to update shipments table in dms for this one record

  --update s
	set SHIPMENTHOLD_FLAG = 0
  -- select *
  FROM [DMSServer].[dbo].[shipments] s
  where SHIPPER_SHIPMENT_REFERENCE = 'RA0000042242'
  and SUID = '91529617-3C06-46BA-9A09-81DC253A480A'

-- after manifest is created for other 6 ^^
-- may also have to void manifest record with invalid tracking
vskip 

/*							ATP-13421
							VAY - manual send of ARN
							12/6/18 - 12/13/18
-- ticket from josh VAY arn 856
routing guide amazon
 ARN
 as ASN
 change shipmethod
 where arn = '' dont send 856 when small parcel like amazon

 manually enter ARN for this ticket and get that sent
 5600268363 

 VA0000045073
***************************** this is for LTL asn send****************************************
--update ls
	set ASN = '5882614213',
		EDIStatus = 0
--select *
FROM SCPRD.wmwhse1.LTLShipment ls with (nolock)
	INNER JOIN SCPRD.wmwhse1.LTLShipmentPallet lp with (nolock)
		ON ls.shipmentkey = lp.shipmentkey
	INNER JOIN SCPRD.wmwhse1.Pickdetail pd with (nolock)
		ON lp.palletkey = pd.dropid
	INNER JOIN SCPRD.wmwhse1.Orders wo with (nolock)
		ON pd.orderkey = wo.orderkey
	inner join lebanon.dbo.ship_method sm (nolock)
		on sm.ship_method_id = wo.intermodalvehicle
where-- ls.DepartureDate < GETDATE()
--		AND ISNULL(ls.custom1, '') <> ''															--	Some Data/ID Field. Looks like it needs to be populated
		 --pd.qty > 0 
		--pd.dropid <> ''
		wo.storerkey = 'LSK'
		and sm.[service_name] = 'LTL'
		and wo.externorderkey in ('LK0000010044','LK0000010045','LK0000010046') -- = 'VA0000067066'
		-- in ('VA0000067068','VA0000067067','VA0000067066')
***************************** end LTL asn send****************************************

 according to fulfill tran this has been updated 12 times 
 after being allocated but never to shipped even though
 the 856 sent this out already or ltl ship conf

select *
FROM SCPRD.wmwhse1.LTLShipment ls with (nolock)
	INNER JOIN SCPRD.wmwhse1.LTLShipmentPallet lp with (nolock)
		ON ls.shipmentkey = lp.shipmentkey
	INNER JOIN SCPRD.wmwhse1.Pickdetail pd with (nolock)
		ON lp.palletkey = pd.dropid
	INNER JOIN SCPRD.wmwhse1.Orders wo with (nolock)
		ON pd.orderkey = wo.orderkey
where ls.DepartureDate < GETDATE()
--		AND ISNULL(ls.custom1, '') <> ''															--	Some Data/ID Field. Looks like it needs to be populated
		AND pd.qty > 0 
		AND pd.dropid <> ''
		AND wo.storerkey = 'VAY'
		and wo.C_CONTACT1 like 'Amazon%'
	--	and wo.INTERMODALVEHICLE not in (15041,15040,15030)
		and ls.asn <> ''
	--	and (case when wo.C_Contact1 like 'Amazon%' then
			-- case when wo.intermodalvehicle not in (15041,15040,15030) and ls.ASN <> '')
		--and wo.EXTERNORDERKEY = 'VA0000045073'

trying to get nested case (maybe) or case to work in where clause
not sold on it but will try to combine some filters
2nd iteration below vv
select *
FROM SCPRD.wmwhse1.LTLShipment ls with (nolock)
	INNER JOIN SCPRD.wmwhse1.LTLShipmentPallet lp with (nolock)
		ON ls.shipmentkey = lp.shipmentkey
	INNER JOIN SCPRD.wmwhse1.Pickdetail pd with (nolock)
		ON lp.palletkey = pd.dropid
	INNER JOIN SCPRD.wmwhse1.Orders wo with (nolock)
		ON pd.orderkey = wo.orderkey
where ls.DepartureDate < GETDATE()
--		AND ISNULL(ls.custom1, '') <> ''															--	Some Data/ID Field. Looks like it needs to be populated
		AND pd.qty > 0 
		AND pd.dropid <> ''
		AND wo.storerkey = 'VAY'
		and (wo.C_Contact1 like 'Amazon%' and wo.intermodalvehicle not in (15041,15040,15030) and ls.ASN <> '')
		or (wo.C_Contact1 like 'Amazon%' and wo.intermodalvehicle in (15041,15040,15030))
		--and wo.EXTERNORDERKEY = 'VA0000045073'
		--and wo.C_CONTACT1 like 'Amazon%'
		--and wo.INTERMODALVEHICLE not in (15041,15040,15030)
		--and ls.asn <> ''

final iteration for today 12/6/18 and is mostly working haha
--added update for ticket request 
--INCLUDES THE WHOLE QUERY BELOW IN UP SANS CASE STATEMENT
--update ls
	set ASN = '5600268363',
		EDIStatus = 0

select *
FROM SCPRD.wmwhse1.LTLShipment ls with (nolock)
	INNER JOIN SCPRD.wmwhse1.LTLShipmentPallet lp with (nolock)
		ON ls.shipmentkey = lp.shipmentkey
	INNER JOIN SCPRD.wmwhse1.Pickdetail pd with (nolock)
		ON lp.palletkey = pd.dropid
	INNER JOIN SCPRD.wmwhse1.Orders wo with (nolock)
		ON pd.orderkey = wo.orderkey
where ls.DepartureDate < GETDATE()
--		AND ISNULL(ls.custom1, '') <> ''															--	Some Data/ID Field. Looks like it needs to be populated
		AND pd.qty > 0 
		AND pd.dropid <> ''
		AND wo.storerkey = 'VAY'
		and case
			when wo.C_CONTACT1 like 'Amazon%' and wo.intermodalvehicle not in (15041,15040,15030) and ls.ASN <> '' then 1
			when wo.C_Contact1 like 'Amazon%' and wo.intermodalvehicle in (15041,15040,15030) then 1
			when wo.C_CONTACT1 not like 'Amazon%' then 1
			else 0
			end = 1

notes from josh finish the query using ship or carrier type instead of C_Contact
--update ls
	set ASN = '5600268363',
		EDIStatus = 0
select *
FROM SCPRD.wmwhse1.LTLShipment ls with (nolock)
	INNER JOIN SCPRD.wmwhse1.LTLShipmentPallet lp with (nolock)
		ON ls.shipmentkey = lp.shipmentkey
	INNER JOIN SCPRD.wmwhse1.Pickdetail pd with (nolock)
		ON lp.palletkey = pd.dropid
	INNER JOIN SCPRD.wmwhse1.Orders wo with (nolock)
		ON pd.orderkey = wo.orderkey
	inner join lebanon.dbo.ship_method sm (nolock)
		on sm.ship_method_id = wo.intermodalvehicle
where ls.DepartureDate < GETDATE()
--		AND ISNULL(ls.custom1, '') <> ''															--	Some Data/ID Field. Looks like it needs to be populated
		AND pd.qty > 0 
		AND pd.dropid <> ''
		AND wo.storerkey = 'VAY'
		and sm.[service_name] = 'LTL'

-- simple as that apparently^ just add ship method and filter for ltl		

0000322464
0000322525


-- Also just sent both out through test execution on friday 12/7 for small parcel
-- confirmed data sent not sure whether it was entirely what they expected
-- after email they sent over the weekend
-- fixed the LTL process and still have to manually send small parcel fixes
-- get with josh on new ticket he is making for tool or changes

--update for flexfield14 aka asn for small parcel process
--update fo
  set fo.flexfield14 = '5600268363'
--select *
FROM wms_PICKDETAIL pd with (nolock)
INNER JOIN wms_ORDERDETAIL od with (nolock)
	ON pd.orderkey = od.orderkey
	AND pd.orderlinenumber = od.orderlinenumber
INNER JOIN Orders o with (nolock)
	ON od.externorderkey = o.primary_reference
INNER JOIN Orders_FlexFields fo with (nolock)
	ON fo.orders_id = o.orders_id
INNER JOIN Orders_Flexfields ox with (nolock)
	ON o.orders_id = ox.orders_id
INNER JOIN fulfillment_transaction f with (nolock)
	ON  f.trans_key01 = o.orders_id
INNER JOIN Inventory i with (nolock)
	ON od.sku = i.primary_reference
	AND i.fulfillment_id = 1162
LEFT JOIN vw_Manifest m with (nolock) 
	ON o.primary_reference = m.order_primary_reference
	AND pd.caseid = m.caseid
LEFT JOIN (
	SELECT 
		order_primary_reference, 
		cartons = COUNT(*), 
		[weight] = SUM(weight)
	FROM vw_Manifest with (nolock)
	WHERE LEFT(order_primary_reference, 2) = 'VA'
	GROUP BY order_primary_reference
) mc
	ON o.primary_reference = mc.order_primary_reference
LEFT JOIN ship_method sm with (nolock)
	ON o.ship_method_id = sm.ship_method_id
WHERE o.fulfillment_id = 1162
	AND  fo.flexfield6 = 'VAY_EDI_ORDER'
--	AND o.consign like 'AMAZON%'																	--	#TODO: Evaluate all WHERE clause statements for new implementation
	AND o.ship_method_id not in (15040,15041,15044,15045,90005)										--	#TODO: Update - This is a Small Parcel Check but F+W and VAY likely use different ship methods.
	AND o.add_date > dateadd(month, -3, getdate())													--	#TODO: Evaluate. Update. Maybe we can use something like this to do our 'PRE-AS2' check in the LTL version...
	AND o.order_status = 'SHIPPED'
	AND f.trans_module = 'ORDERS'
	AND f.trans_submodule = 'SHIPPED'
	AND ISNULL(f.trans_status,'0') = '0'
	AND pd.qty > 0
	--AND ISNULL(pd.DROPID, '') = ''
	and o.primary_reference in ('VA0000045073') 
	-- and for other primary ref
WHEN USING TEST MODE EXECUTION THE EDI'S WILL GO TO TEST OUT FOLDER
HAVE TO COPY TO PROD AND ITLL TRANSMIT VIA AS2

example of working taskdetail joined on pick detail using caseid

select *
FROM wms_PICKDETAIL pd with (nolock)
INNER JOIN wms_ORDERDETAIL od with (nolock)
	ON pd.orderkey = od.orderkey
left join scprd.wmwhse1.taskdetail td (nolock) on td.caseid = pd.caseid
INNER JOIN Orders o with (nolock)
	ON od.externorderkey = o.primary_reference
WHERE o.fulfillment_id = 1162
--	AND o.consign like 'AMAZON%'																	--	#TODO: Evaluate all WHERE clause statements for new implementation
	AND o.ship_method_id not in (15040,15041,15044,15045,90005)										--	#TODO: Update - This is a Small Parcel Check but F+W and VAY likely use different ship methods.
	AND o.add_date > dateadd(month, -3, getdate())													--	#TODO: Evaluate. Update. Maybe we can use something like this to do our 'PRE-AS2' check in the LTL version...
	AND o.order_status = 'SHIPPED'
	AND pd.qty > 0
-- end 13421

RA41592
RA41591
RA41590
RA41585
RA41584

_________________________________________________________________________________________________________
/*							ATP-12851
							Need to understand how lot08 is connected to
							stop ship in the system. 
							12/10/18 - 12/-

use or look up lotxlocxid for issues with stop ship
possibly have expired items
[dx_Inventory_Stop_Ship]
or 
/* Object:  StoredProcedure [dbo].[pr_Report_Inventory_StopShip] Script Date: 12/10/2018 3:04:00 PM */
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[pr_Report_Inventory_StopShip]
(
	@fulfillment_id int,
	@daysremaining int
)
AS
SET NOCOUNT ON

SELECT * 
FROM Event_Inventory_StopShip
WHERE fulfillment_id = @fulfillment_id
	AND daysremaining > @daysremaining
	
--131
GO



/*
notes on logging into mc9596 scanners 
use infor mass or mastemp10?
go in to wifi select fusion button and connect to rf for mason and WC for leb
use infor login likes james 1477 instead if mastemp
in scan menu
6 for pick
1 cluster
1 caseid
enter
enter
scan caseid

according to online search may need to configure laser reads in apps

taos Seph test wave 0000256830

TO DO
starting memorizing more tables.views.procs by DBO
start Brainpower Hour
group and lead team in discussion on a wish list
or ideal things to work on and what ideas we individually have to better Aero
this would be maybe 30 mins monday afternoon and 30 mins fri.
id document and encourage others to build upon ideas shared to define
more clearly and logically. why these can work and xyz


back up or alt ideas?
-- solo stuff? what can i build or offer to team?
-- what kind of things do we need help with or just quality of life stuff?
-- do we have good documentation habits? comment /documentation reviews 
-- that could show each other what we like as far as changelog and details
-- for how we put notes in comments and such

--- create documentation for Tips & Tricks?
--- to share with others how we use certain keybinds, scripts, macros,
--- and whatever else we find useful utils to help each other grow

-- boomi job notes
store in boomi properties for every fulfill with a primary CE
storerkey or ff ID

_________________________________________________________________________________________________________
/*							ATP-12484 -12894 linked tickets
							CPG Reorder tool order not falling off correctly
							11/16/18(due) - 12/-
ATP-12484

Items that have approved reorders are not following off the Reorder Approve Tab
CPG - POs that have been approved are not falling off of the report pulled from 
the Reorder Tool. This causes P&G's team to mistakenly re-order.

need to find root cause and search in report/ stored proc to find 
exactly what is causing this issue and why its there in the first place

check this item 00000571

using item 03567755 because its showing up on approve page and active reorders
page.
believe something wierd going on in [pr_report_CPG_InventoryReorderPO]
because in windows nav i see trans status = 5 and ff id 73 as default
in this proc though the filter is trans status > 5 so need to double check
these a bit report 2455
james showed me to use store proc or a query to see what was going on with the specific
item 00000571

get item id from inventory
then query it on inventory_reorder

select * from inventory (nolock) where primary_reference = '00000571'
select top 1000 *
from inventory_reorder 
where item_id = '167228' 
--fulfillment_id = 73 
--and po_number is not null
order by date_below desc

_________________________________________________________________________________________________________
/*							ATP-13436 
							Change default ship method on CPG nav batch order home page
							12/13/18 - 12/

checking in afsterm01 box for windows nav because its my first instinct

from james:
pr_Fulfillment_Ship_Method_SelectByFulfillment_IdByRoleCulture

loaded this into visual studio - Aero10 
(C:\Users\ben.yurchison\OneDrive - Aero Fulfillment Services Inc\Documents\GitHub\aero-navigator\Aero10)
trying to track down where to change default on shipmethod dropdown list

first found ctrl_BatchOrderSubmit.ascx then WebUtils.vb then WebControlBuilder.vb
in batch order submit: <label for="<%=drpShipMethod.clientid%>" class="formLabel">
            Ship Method</label>
        <asp:DropDownList ID="drpShipMethod" name="drpShipMethod" EnableViewState="False"
            runat="server" CssClass="dropDown" Width="310px">
        </asp:DropDownList>

in web control builder:  Public Function CreateShipMethod(ByVal nField As Field) As WebControls.DropDownList
line 1178

not sure if either of these can help me change the default ship method that shows up

viewing code behind of batch order submit and see some code for defaultview of datasource. not sure where 
or how to change this but i may be getting much closer.

Cory [2:41 PM]
"i'm thinking it is ultimately looking at a list which means you would only need to do a DB update
need to look at GetShippingMethodsForCustomer
and/or businessRules.OrderProvider"

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [fulfillment_id]
      ,f.[ship_method_id]
      ,[role_ids]
      ,[require_ship_bill_account]
      ,f.[sur_charge]
      ,[bill_role_ids]
      ,[account_number]
      ,[sequence]
      ,[user_description]
      ,[culture]
	  , s.*
  FROM [ENTERPRISE].[dbo].[Fulfillment_Ship_Method] f(nolock)
  join mason.dbo.ship_method s (nolock) on s.ship_method_id = f.ship_method_id
  where f.fulfillment_id = 73

-- where does efulfillment get told to target a .NET framework version? do i need to put the new framework DL
-- into an nav folder on my machine?
-- my github is in users ben docs BDOCS github
-- but where are the packages within VS or aero10
/*
_________________________________________________________________________________________________________
/*							ATP-13439 
							Please fix skip slot report
							12/13/18 - 12/

Please make skip slot report function correctly for RAS/AOS on sorter zones.

When the picker skips a slot it should populate on the skip slot report the item, lot, location, 
and user who skipped it.

Please also add exceeded inventory and other constraints to this report.
This report is not working for aisle's 620, 635, 640.

#BSY updated?							

_________________________________________________________________________________________________________
/*							ATP-13040 
							Add PR to state dropdown for sykes global P&G charmin
							11/5/18 - 12/18/18


Cory [4:04 PM]
its a microsite that lives on PDWEB01 and PDWEB02
looks like its build on Zend framework
here's the file you'll need to look at..
 \\pdweb01\E$\projects\PG-Charmin-Microsite\module\Charmin\src\Charmin\Form
CharminForm.php
 use conf doc Aero Central PHP APIs - guide lines

looks like this needs to be changed in github as the states were added there.
using github desktop in the charmin repo 
click repository tab at top and select view on github
once at the web page navigate to the folder above containing CharminForm.php
then click the blame button and see if anyone has entered the data that needs manipulated
 in this case we find that the states are entered here so we cannot just change the
 file using notepad++. 

 need to see how to properly edit this using github desktop?
 go to IIS on UATWEB02 box and browse URL after finding site in left column drop down.
 browse option in right column of screen

uat site https://charminspindle-uat.aerofulfillment.com/

brain power: 1.5 because the box HOSTING the site and data of project is technically a local repo 
to use in github desktop. shouldnt clone whats already existing locally. 
finally showing up in UAT site however there are other changes that are in dev and i cannot merge
my change until those are reverted
correct path in web02 box:
E:\projects\charminspindle\module\Charmin\src\Charmin\form\CharminForm.php

/*							CI-203 
							Set up child meter for Zevo fulfillment
							12/15/18 - 3/5/19
following email chain from jean and cory. looks like this needs new license for FF address
also update origin addy from UPS (believe UPS has to do this) then i can update in VXE

accounts provisioned with CLS handoff to cory.
going to have to consider for PRE print
for a process that doesnt currently exist.

HOUND JEAN TO PUSH PROJECT ALONG -- need to push Learning Works cuz this is near deadline

ill set up TMS once given info

going to work on project to re write tms to lookups
so we can have this auto set up

test caseid for devtms
0065029945

test prod tle- zevo cost center -caseid 2022306169


_________________________________________________________________________________________________________
/*							ATP-13515 
							Please update PO to 959874-OAK on shipped order FI0000197030.
							12/17/18 - 12/17/18
-- looks like only an update to two fields. order export map says reference_3 which was blank originally
-- but susr3 wasnt so updating both

select *
from lebanon.dbo.orders o (nolock)
left outer join lebanon.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
where o.primary_reference = 'FI0000197030'

-- w.SUSR3 and o.reference_3 set to '959874-OAK' i believe?

--update o
	set o.reference_3 = '959874-OAK'
--select *
from lebanon.dbo.orders o (nolock)
left outer join lebanon.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
where o.primary_reference = 'FI0000197030'
and w.storerkey = 'AFI'

--update w
	set w.SUSR3 = '959874-OAK'
--select *
from lebanon.dbo.orders o (nolock)
left outer join lebanon.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
where o.primary_reference = 'FI0000197030'
and w.storerkey = 'AFI'

_________________________________________________________________________________________________________
/*							ATP-13601 
							SL0000040114 order shipped (physically?) but can not change status (nav and infor?) to ship comp
							12/18/18 - 12/18/18

queried fulfill tran and stuck in allocated.
infor shows 6 lines 2 zero shipped 3 shipped complete and 1 in picked complete
doesnt look like user temp2 finished picking or shipping this item

doug said they will try to fix on their end.

/*							ATP-13451
							Our ship site needs to ensure that all cases are ‘case labeled’. If not, then the appropriate MAN*GM
							will not be sent, as is called out in the email below by NMG. 
							12/18/18 - 12/

-- UT0000002929 sku 81675698
has to be part of PAY but which boomi job?
Need to find that then see how things are mapped. test



_________________________________________________________________________________________________________
/*							ATP-12582
							Navigator rep 1308 pre cycle count post variance not returning appropriate counts
							10/18/18 - 12/19/18

had this ticket for a bit but barely worked on it.
going back to the thinking i originally had i believed to be an issue strictly with the math of 
a.qty - or / b.qty was off or incorrect somehow. but why? seemed like the first thing to look at when
told it isnt giving proper results.
once i changed approach to taking the query apart many times
is appears that selecting cckey & ccdetailkey - unique and also joining on this kept the skus from matching
and pulling by 1 line or row per sku instead of cckey which maybe inherrently was designed to
pull how the tables have the skus already separated by loc or lot.
but even those keys werent the only thing causing this issue.
we also use:
lli.qty AS qtyonhand,
	ccd.qty AS qtycounted,
in the select which means these values are probably also pulling unique lots or locs

REWORK
-- going to do similar with above but adding a temp table to store sum results
create table #counts (sku varchar(25),qtyonhand int, qtycounted int)
insert into #counts
SELECT
	ccd.sku,
	SUM(lli.qty) AS qtyonhand,
	SUM(ccd.qty) AS qtycounted
FROM wms_CCDETAIL ccd with (nolock)
INNER JOIN wms_CC cc with (nolock)
	ON cc.sku = ccd.sku
INNER JOIN wms_SKU s with (nolock)
	ON ccd.storerkey = s.storerkey
	AND ccd.sku = s.sku
INNER JOIN wms_LOTxLOCxID lli with (nolock)
	ON ccd.loc = lli.loc
WHERE cc.status = '3'
group by ccd.sku

-- select * from #counts
-- drop table #counts

SELECT distinct ccd.sku,
	ccd.storerkey,
	--ccd.sku,
	--c.sku,
	s.descr,
	lli.status,
	--ccd.lot,
	--ccd.loc,
	--ccd.id,
	lli.qtyallocated,
	lli.qtypicked,
	c.qtyonhand AS qtyonhand,
	c.qtycounted AS qtycounted,
	c.qtycounted - c.qtyonhand AS qtyadjusted,
	CASE WHEN c.qtyonhand = 0 THEN 100 ELSE (CONVERT(float,c.qtycounted - c.qtyonhand) / CONVERT(float,c.qtyonhand)) * 100 END AS variance
FROM #counts c with (nolock)
inner join  wms_CCDETAIL ccd(nolock) on c.sku = ccd.SKU
INNER JOIN wms_CC cc with (nolock)
	ON cc.sku = ccd.sku
INNER JOIN wms_SKU s with (nolock)
	ON ccd.storerkey = s.storerkey
	AND ccd.sku = s.sku
INNER JOIN wms_LOTxLOCxID lli with (nolock)
	ON ccd.loc = lli.loc
WHERE cc.status = '3'
order by variance			-- #BSY looks better and less changing than select sequence

--test section to verify if temp insert worked to pull all data by sku 
select *
from wms_CCDETAIL ccd with (nolock)
INNER JOIN wms_CC cc with (nolock)
	ON cc.sku = ccd.sku
--inner join #counts c (nolock) on c.sku = ccd.SKU
INNER JOIN wms_SKU s with (nolock)
	ON ccd.storerkey = s.storerkey
	AND ccd.sku = s.sku
INNER JOIN wms_LOTxLOCxID lli with (nolock)
	ON ccd.loc = lli.loc
where ccd.sku = 'T0395'
-- sku 15KN05 or try 670535728313
-- both skus are correct but how do we fix skus that still show dupes even though math is correct
-- repeating sku T0395 so its showing a record in final select for each row of lli.sku it finds. PLUS lli skus arent matching ccd.skus 
-- so its a little confusing since they dont match but it doesnt show the splits in the select * for #counts 
-- but it does show the correct variance and qtys even though its duplicated. going to see how this looks just showing c.sku (#counts.sku)
-- still not working so i should look at the joins and what theyre on. 
-- finally found the bigger work around. distinct sku works but will still have dupes based on other selects like status, loc, lot, and qtyallocated
-- shouldnt need these 100% so commenting out lot and loc for now but will confer with michael zwaap.

_________________________________________________________________________________________________________
/*								atp-blank 
								boomi job failing on ATK process in UAT only
basically ATK Premium Orders Master always shows 1 in
then stats sub processes which are more distinctly failing at start shape due to 'no such file'
checked all the revisions and it turns out almost everything is up to date and doesnt look like 
much could be changed

eventually after clicking through all the processes and maps went back to process reporting
looked at the boomi info it was displaying and it shows a clickable error log which pulls up
Process error details. the stack trace didnt seem entirely easy to dissect but the steps with 
clickable links to where errors probably occurred is where I found some success
first 2 links showed me things that didnt have something to be manipulated through boomi or data
which was Aero sFTP rev 10 which wasnt current but not truly different?
2nd was ATK SFTP GET rev 4 which has no changes whatsoever
3rd was ATK properties file
this hinted me to look at SFTP filezilla
and i noticed for ATK-test there was no test\IN or test\OUT to put data in? this looks extremely
relevant and josh said to recreate those directories.
this runs every 15 mins and seemingly replacing those directories was all that was needed for fix.
*/
_________________________________________________________________________________________________________
/*							ATP-13562 & ATP-13563
							AFI and AWI EOM process
							12/20/18 - 12/21/18

starting to run queries for validation on 12/20
as long as all the results are good i can begin the process tomorrow
0 results for all the AWI queries

AFI first line item select - out of all queries this is only one found for flexfields 1-4
lineitem_id	orders_id	line_type	item_id	item_desc	inventory@primary_reference	flexfield1	flexfield2	flexfield3	flexfield4	flexfield5	flexfield13	edit_who_name	vendor_name	vendor_status
222910937	37912783	WEB	339571	Medtone and Medtech HOM Sheet Brochure	FP7440F9519					C5511722049571	C5511722049571	LISA D KERKORIAN	BOTH	

will need to do an update to the ff's for this order and then everything will be set for tomorrow
emailed kelly with FP7440F9519 stating missing ffs. she will add on her end in some system(?) and the
ill use update to fix in backend

-- used to find the order # from messed up lineitem in validation queries
select * -- could have just selected o.primary_reference, l.* but both work okay
from lineitemsearch l(nolock)
join orders o (nolock) on o.orders_id = l.orders_id
where l.fulfillment_id = (select fulfillment_id from Fulfillment where short_name = 'AFI') and
l.[add_date] > convert(datetime,convert(varchar,getdate()-35,101)) and o.orders_id = 37912783


--update l
set flexfield1 = 'C5511722040173', flexfield2 = 'C55125101FGNBSCTRL', flexfield3 = 'C5511722040173', flexfield4 = 'C5511722040173'
--select *
from lineitemsearch l(nolock)
where orders_id in (37912783)
 and lineitem_id in (222910937)
and fulfillment_id = (select fulfillment_id from Fulfillment where short_name = 'AFI') and
[add_date] > convert(datetime,convert(varchar,getdate()-35,101)) and
isnull(flexfield13,'')<>'' and 
isnull(vendor_status,'')='' and qty_shipped>0 and
line_status = 'SHIPPED' and inventory@primary_reference<>'99999' --and (left(isnull(flexfield13,''),4)

-- for atp-13625
--VA0000058225 or VA0000060221 or VA0000033884

_________________________________________________________________________________________________________
/*							ATP-13632 also atp-14080 and atp-14067
							Please close out LK10089 and LK10090
							12/21/18 - 12/28/18
CHECK TO SEE IF LTL OR NON LTL 
in ship confirm proc someone had turned parcel off

turn off 3pl boomi job
in 3pl ltl ship conf 3 add in hard coded orders
in ship conf comment out line 72 and uncomment 74 (ltl off)(ltl 3 on)
then exec main ship conf proc through boomi job	
issue due to OPS force shipping and not properly 

missing dropids per case and not possessing dropids that are in
ltlmanager /ltlshipmentpallet. 2 different issues from OPS.
James Cardwell [3:46 PM]
one is that they are using drop ids that do not exist in ltl manager
two is that they didn't add drop ids to all cases
These are the root cause
We can force send this
Take a look at [dx_3PL_ShipConfirm_LTL3]

_________________________________________________________________________________________________________
/*							ATP-13652
							SQL SQL exception
							12/27/18 - 12/28/18

checking logs to see error occurrances and find out what may be causing
error:
(12/27/18 1:39:52 PM EST) 13:28:30.876 - 20370671: ##java.sql.S Q L Exception:
 Incorrect syntax near ')'., To continue say ready##;pp
caseid
0071385307

waves 
 0000323996, 0000323999, 0000324004, 0000324009

 these errors look entirely based on things inside voice that we dont really
 control or effect our picks specifically

 only one order(RA0000043028) with sku 81605868 
 could possibly see any symptoms (unconfirmed if related) to this SQL error
 more than likely its corrupt data on infor's side.
 going to reach out to them

infor wants to see this error with an example of this happening live without it already being picked and shipped.

per [~matt.marischen]
we will have to wait another week or so to get an order with this error and not already picked 
and shipped to provide to infor for research

_________________________________________________________________________________________________________
/*							ATP-13653
							Mason RF Guns
							12/28/18 - 12/28/18

taking a look at 4 rf guns from mason
1 broken trigger - not fixable with current equipment
1 start screen loop - trying to reset - warm and cold boot didnt change status
of screen not displaying anything even though it is still reading the
software
2 with connection issues - one screen is wild and wont let users change or go 
into menus and change settings effectively
#8 / new #3 - is scanner with issue changing settings and not connecting
need to check if this scanner is under warranty s/n 7361000508110 last digits unclear


notes on logging into mc9596 scanners 
use infor mass or mastemp10?
go in to wifi select fusion button and connect to rf for mason and WC for leb
use infor login likes james 1477 instead if mastemp
in scan menu
6 for pick
1 cluster
1 caseid
enter
enter
scan caseid

not on network correctly still for new#3 and screen still not allowing settings to be changed.
told doug that they should order new scanner chargers and new scanners
emailed wade and will see about next steps if this is something dean should handle himself

#RFDOC ------------------- use this to configure RF guns -------------------------------
RF Scanners

aerowh Fall#9375

General Notes - ma99RF#% - system
•	The avalanche program should automatically load upon reboot of RF again unless using one of the guns with the handles.
 If you are using one of the guns with the handle exit symbol to do this you will need the enter the password “manage”
•	For the other RF scanner the password to exit the program and work inside windows is “config”
•	If no wireless set up configure by clicking on wireless icon in the lower right hand corner. 
 -- ^^^^ idk what above is talking about ^^^^^ -----------

New RF Scanner Setup
1.	Plug cradle into your laptop, depending on the RF model you will need to use the correct cradle. 
2.	Next you will need to go to \\aeroshare03\it\wavelink\client and deploy the exe the matches with the model RF you are using. 
3.	After completing that step you can unplug and re-plug the cradle back in to bring up the windows media controller 
form here chose “connect with setting up device”
4.	You should now be at the below screen.

Simple explanation -- #bsy
First thing click button right network icon and set up a profile for aerosecure/AeroRF
After profile is set up use same menu but select find WLANs
Connect to aerosecure or aeromason

After that we start the systems set up. First copy specific RF gun model config file into app folder
Then copy the app center file for correct RF model into app folder.
Now we go into wavelink software (for now MC models)
Click host profile option and make sure host settings are correct 
- Add \0 to end of pw to set up autologin or auto session start?
-	Afsinfor01 is leb
-	Afsinfor02 is mason
To make use of these understand that for now (until we create a subnet where one RF gun can talk to both hosts) you can only have 01 or 02 not both. So rf gun A cant work in both mason and leb at same time.
After host iP is set click autologin and enter correct login info per warehouse
-	Mas-rf for mason login ma99RF#% pw
-	Wc-rf for leb/west chester login a3r03900 for pw?
After these are set hit okay and we will now install app files and confg files
Click button for both App and config
Hit okay if prompted to install and select telnet
On rf gun have telnet install in location device (which is default)

5.	From here you will want to click on “enable Settings” this will bring up a menu with multiple tabs. Under 
connection tab check “configure server address” and put in 192.168.0.10.
6.	Next click on the Wireless tab check the “Configure wireless settings” and add the SSID and encryption type for the wireless. 
a.	Mason: ma99RF#% 
b.	Fairfield: a3r03900
7.	Than you will click on the user interaction tab and check “Secure Settings with Password” and “Prompt for password
 when exiting Monitor”. The password for both these boxes should be config. 
a.	Secure Settings: “system”
b.	Exit: “symbol”
8.	Click ok and you will be back at the original screen here you will click “Application & Config”. This will send the 
information to the device. Once completed the device will be ready to go. 
- 

Don’t click okay on computer until finishing install steps on RF gun

Afterwards hit okay and remove from cradle/charger
Do a cold boot – start by pulling battery out slightly
For trigger models hold power button and click trigger a few times
And insert battery yellow light should flash before turning on if successful
Non trigger models hold 1 and 9 and power button or try holding 1 and 9 and repeatedly pressing power. Should also flash yellow/orange light if it worked

Now make sure it loads telnet software correctly and make sure internet is working

a3r03900

1st RF from leb to mason not a trigger model - working at mason
serial: 7115000501734

2nd RF from leb to mason trigger model - working at mason
serial: 1709900502800

new gun received for mason - trigger model - working at mason
serial:11073000507449

all guns except mason RF 4 are working but 2 MC are only connecting to afsinfor01

_________________________________________________________________________________________________________
/*							ATP-13645
							International orders not being shipped through UPS
							station. error message 'harm code is missing'
							12/28/18 - 
See orders VA0000061722, VA0000061719, VA0000062301. 
kelly said that when trying to ship via DHL that its giving the error
harmonized code is missing - thinking its trying to map or require item
harmonized tariff codes for DHL international expedited shipping

james pointed to TMS_ITEM_INTERFACE
in this case statement we see what should be causing the error:
CASE WHEN s.storerkey = 'FW' THEN ISNULL(ix.flexfield34,'')		--10/17/2014
		--(added by Lee Peavy on 6/22/2017 )
			ELSE ISNULL(inv.harmonized_code,'')
			END AS ITEM_HARMONIZED_CODE,
			CASE WHEN inv.manufacture_origin = '' THEN 'US'
			     WHEN inv.manufacture_origin = ' ' THEN 'US'
				  WHEN inv.manufacture_origin = 'USA' THEN 'US'
				 WHEN inv.manufacture_origin = 'NULL' THEN 'US'
			     WHEN inv.manufacture_origin is null THEN 'US'
				 else RTRIM(inv.manufacture_origin)
				 END AS ITEM_MANUFACTURE_COUNTRY,

So basically VAY inv.harmonized_code is missing on an item or more that
was on these orders

email back from kelly stating she checked and the items did have harm codes
- were they valid?
- i have to check


select *
from Lineitem l(nolock)
join Inventory inv(nolock) on inv.item_id = l.item_id
where order_primary_reference in ('VA0000061722', 'VA0000061719', 'VA0000062301')
all codes are there and doesnt look like typo or anything..

now repurposing TMS item interface for these orders/lineitems:

SELECT 	RTRIM(pd.caseid) as ARO_CASE_ID,
		RTRIM(od.ExternOrderKey) as ARO_ORDER_NUMBER ,
		pd.Qty as ITEM_QUANTITY,
		RTRIM(od.sku) as ITEM_NUMBER,
		RTRIM('PCS') as ITEM_QUANTITY_UNIT_MEASURE,
		RTRIM(isnull(s.DESCR,'')) + CASE WHEN ISNULL(inv.harmonized_code,'') <> '' THEN ' (' + ISNULL(inv.harmonized_code,'') + ')' ELSE '' END as ITEM_DESCRIPTION,
		CASE WHEN s.storerkey = 'FW' THEN ISNULL(ix.flexfield34,'')		--10/17/2014
		--(added by Lee Peavy on 6/22/2017 )
			ELSE ISNULL(inv.harmonized_code,'')
			END AS ITEM_HARMONIZED_CODE
FROM wmwhse1.PickDetail pd with (nolock)
	 INNER JOIN wmwhse1.SKU s with (nolock)
	  ON pd.storerkey = s.storerkey AND pd.sku = s.sku
	 INNER JOIN wmwhse1.OrderDetail od with (nolock)
	  ON pd.orderkey = od.orderkey AND pd.orderlinenumber = od.orderlinenumber
	 INNER JOIN LEBANON.DBO.OrdersEdit OE WITH (NOLOCK) --SBusam - 5/31/18
		ON OE.PRIMARY_REFERENCE = OD.EXTERNORDERKEY
	 LEFT OUTER JOIN LEBANON.dbo.Lineitem l with (nolock)
	  --ON od.externorderkey = l.order_primary_reference AND od.externlineno = l.line_number
      ON convert(Varchar(500),od.externorderkey) = l.order_primary_reference AND convert(Varchar(500),od.externlineno) = l.line_number
	 LEFT OUTER JOIN LEBANON.dbo.inventory inv with (nolock)
	  ON inv.primary_reference = s.sku and inv.fulfillment_short_name = s.storerkey
	 LEFT OUTER JOIN LEBANON.dbo.Inventory_FlexFields ix(nolock) ON inv.item_id=ix.item_id	--10/17/2014 added for FW
WHERE
		od.ExternOrderKey in ('VA0000061722', 'VA0000061719', 'VA0000062301')
		AND pd.qty > 0

the righttrim looks to be working fine. bth places i see using inv harmonized code pull it correctly.
makes me think something is wrong with the way dhl international is connected to nav?

no other places where inv Harm codes would be tied to shippers so I believe this was just database
-locking or some hiccup during the import where the error wouldve appeared.

_________________________________________________________________________________________________________
/*							ATP-13675
							please void following wave - 0000324515
							12/31/18 - 
0000324515

check order number against dmsserver
get an order number from the wave and check the dmsserver for that shipment
Confirm that there is a shipment for each orders in the wave.
buid = 
suid = unique shipper ID from DMSserver

get all orderkeys from specific wave

--select *
from wms_wavedetail
where wavekey = 0000324515

use this to get primary ref for each shipment/order
select *
from wms_orders 
where ORDERKEY in ('0014991600',
'0014991599','0014991598','0014991597','0014991596',
'0014991595','0014991594','0014991593','0014991592','0014991591','0014991590',
'0014991589','0014991588','0014991587','0014991586','0014991585','0014991584',
'0014991583','0014991582','0014991581','0014991580','0014991579','0014991578',
'0014991577','0014991576','0014991575','0014991574','0014991573','0014991572',
'0014991571','0014991570','0014991569','0014991568','0014991567','0014991566',
'0014991565','0014991564','0014991563','0014991562','0014991561','0014991560',
'0014991559','0014991558','0014991557','0014991556','0014991555','0014991554',
'0014991553','0014991552','0014991551','0014991550','0014991549','0014991548',
'0014991547','0014991546','0014991545','0014991544','0014991543','0014991542',
'0014991541')

use this to check if each record in dmsserver.dbo.shipments only has 1 each 
order - this ensures we dont have random extras that may have been worked already 
and split into more shipments

select *
from DMSServer.dbo.shipments (nolock)
where --suid = '79268390-936A-4211-84C8-DF159180E6BE'
SHIPPER_SHIPMENT_REFERENCE in ('FT0003889823',
'FT0003889824','FT0003889825','FT0003889826',
'FT0003889827','FT0003889828','FT0003889829','FT0003889830','FT0003889831',
'FT0003889832','FT0003889833','FT0003889834','FT0003889835','FT0003889836',
'FT0003889837','FT0003889838','FT0003889839','FT0003889840','FT0003889841',
'FT0003889842','FT0003889843','FT0003889844','FT0003889845','FT0003889846',
'FT0003889847','FT0003889848','FT0003889849','FT0003889850','FT0003889851',
'FT0003889852','FT0003889853','FT0003889854','FT0003889855','FT0003889856',
'FT0003889857','FT0003889858','FT0003889859','FT0003889860','FT0003889861',
'FT0003889862','FT0003889863','FT0003889864','FT0003889865','FT0003889866',
'FT0003889867','FT0003889868','FT0003889869','FT0003889870','FT0003889871',
'FT0003889872','FT0003889873','FT0003889874','FT0003889875','FT0003889876',
'FT0003889877','FT0003889878','FT0003889879','FT0003889880','FT0003889881',
'FT0003889882')

once we know what we have we can void the entire wave via SC portal
select wave enter wave and action void

nav and infor, however, say these are shipped and thats because manifest data
was created for them.
cory:
as long as the whole wave needs to get voided
but if it wasn't created today then you can't do it in smart connect i dont think
so maybe thats what theyre talking about
cause every night a process runs that 'closes' out each shipment and then you can't void it anymore except with a DB update

update void flag to 1

--update s
	set void_flag = 1
--select *
from DMSServer.dbo.shipments s(nolock)
where --suid = '79268390-936A-4211-84C8-DF159180E6BE'
SHIPPER_SHIPMENT_REFERENCE in ('FT0003889823', ETC)

_________________________________________________________________________________________________________
/*							ATP-13655
							the client has stated stores have started to
							receive shipments but no 945s yet
							12/27/18 - 12/28/18

verified that these were getting fixed and shipped on their own.
looks like Ops Oops due to one line getting part/zero shipped but open 
amount was re released then picked.

since its packed it should mean its been dock confirmed
probably have to do some DB update because i cant just unpick and unallocate.
once this is fixed and shipped the ticket can be closed.

for first pick detail with 0 qty update id to '' and loc to fromloc and status to 5
then set in infor to shipped and save
next 3rd record with qty still need to 0 out in infor change to shipped then set
reason code to out of stock

_________________________________________________________________________________________________________
/*							ATP-10852 & ATP-13488
							Child meter setup for surepost on LW
							1/4/18 -
							
Cory [2:12 PM]
label is referring to the label document, it is some configuration that has to be done to each ship station that will print UPS surepost
surepost is an additional ship method that has to be added to the learning works child meter / shipper account
( i think "child meter" and "shipper" are terms that can be used interchangeably in this scenario )
pretty sure UPS surepost is the equivalent of FedEx SmartPost, where you ship through FedEx but it ultimately gets delivered by USPS (uncle sam)
not sure what that means as far as configuring the shipper for it

need to set up surepost under LW either (and or in) aero TMS_INTERFACE
or just in dms manager shipper config?

check another fulfillment join orders on ship method and look for surepost
then check their config in VXE
will have to manually configure

6 different surepost ship method ids

all cls VXE does is get storerkey from listener to tell
which shipper gets invoice

the actual boomi job or nav will determine which ship method is being used

although for each ship method ship station may need configged to run a certain document

need to ask which specific fulfillment needs to use which specific ship method for surepost
there are several different LW fulfills set up differently with certain ones hard coded


ship_method_id	code		description								service_name
19050	  					UPS SurePost Bound Printed Matter		UPS
19051	  					UPS SurePost Media						UPS
19052	  					UPS SurePost Less than 1 lb				UPS
19053	  					UPS SurePost 1 lb or Greater			UPS
19054						UPS SurePost Less than 1 lb (UPS READY)	UPS
19055					UPS SurePost 1 lb or Greater (UPS READY)	UPS

/*						1/7/19 morning planning meeting

Issue with atk reporting showing 14k orders but nav only showing 3k from 1/5-1/7

onnit issue with phone numbers may look at turning off the requirement
too many orders erroring due to phone numbers with alpha chars 

ultipro super slow when switching jobs

dont need asn or 945 just need 9999 fixed

just need shipped for RAS orders some header may have shipped w/o dropid

already shipped ras transfer 
cannot update dropid because order already shipped? does it need dropid or does it need shipped?

needs dropids so itll ship

1226 and 11.

reach to IC AOS location usage for billing using x of locations
what locs types and what not

flowracks wasnt being captured on reports - try to find the ATP
*/

_________________________________________________________________________________________________________
/*							ATP-13739 & ATP-13747
							Stuck orders not shipping
							OPS Oops not using correct LTL manager process
							1/7/19 - 1/8/19

-- extra notes dropid is essentially MUID and from getting dock confirmed 

-- ras transfers are supposed to be ltl and are transfers from ras to aos or vice versa.

already shipped ras transfer 
cannot update dropid because order already shipped? does it need dropid or does it need shipped?

needs dropids so itll ship

issue with order RA0000042336 is also that it wasnt created in LTL manager at all while other
5 orders were. none had all the correct qualifiers though, meaning we recently added
a requirement that dropid must be on every pickdetail record. other orders needed
an update to the dropid as mentioned since they all had a designated dropid on a few 
pickdetail records so they are a match for the record in ltlmanager ltlshipmentpallet via cory
Cory [3:12 PM]
gotcha. well generally there's a reason the order isn't getting shipped automatically.. we need to fix that reason rather than force ship the order
and the drop ID needs to match a record in wms_ltlshipmentpallet
dropID = palletkey
shipmentkey = ?
^^'0000080397' as ShipmentKey, -- shipmentkey that matches the one auto generated in ltlshipment

so once i updated all the dropids on each order to match (per order) they sent out automatically
via 945. but have to create manifest record since OPS missed a big step on this order
specifically RA0000042336.

-- insert statement for inserting raw data into table to create new record inside that table


insert into manifest (trackingnumber, caseid, order_primary_reference, void, weight, charge, sur_charge, packages, bol, carrier, service, thirdpty, cod_package_flag, consignee_residential_flag, saturdaydelivery_flag, oversize_flag, bill_flag, signature_flag, aro_consignee_billing_flag, aro_freight_collect_flag, tran_date, ship_date, status, add_date, edit_date, add_who, edit_who, billing_period, billing_status, orders_id)
select
	'NO TRACKING' as trackingnumber,
	'0071278362' as caseid,
	'RA0000042336' as order_primary_reference,
	'N' as void,
	600.0000 as weight,
	0.00 as charge,
	0.0000 as sur_charge,
	50 as packages,
	'BLANK' as bol,
	'AERO TRUCK' as carrier,
	'DMS.MSC.TRUCK' as service,
	'N' as thirdpty,
	0 as cod_package_flag,
	0 as consignee_residential_flag,
	0 as saturdaydelivery_flag,
	0 as oversize_flag,
	0 as bill_flag,
	0 as signature_flag,
	0 as aro_consignee_billing_flag,
	0 as aro_freight_collect_flag,
	'2018-12-12 11:33:29.000' as tran_date,
	'2018-12-12 11:33:29.000' as ship_date,
	0 as [status],
	'2018-12-12 06:35:05.180' as add_date,
	'2018-12-12 06:35:05.180' as edit_date,
	'LTLShip' as add_who,
	'LTLShip' as edit_who,
	NULL as billing_period,
	0 as billing_status,
	38000730 as orders_id

manifest record created for this order!!! 

verify

will process auto pick this up now? should see on the hour

it wont auto pick, must require ltlshipment record

insert into lebanon.dbo.wms_ltlshipment (Status,EDIStatus,MBOLFlag,ASN,BOL,MBOL,ProNumber,StorerKey,Consignee,CarrierName,TrailerID,SCAC,ShipFromName,BillToLine1,BillToLine2,BillToLine3,BillToLine4,PaymentTerms,DepartureDate,DeliveryDate,TransmitDate,ResendFlag,Custom1,Custom2,AddDate,AddWho,EditDate,EditWho)
select
	9 as [status],
	0 as EDIStatus,
	'NO' as MBOLFlag,
	'' as ASN,
	'BLANK' as BOL,
	'BLANK' as MBOL,
	'No Pro' as ProNumber,
	'RAS' as StorerKey,
	'' as Consignee,
	'AERO TRUCK' as CarrierName,
	'' as TrailerID,
	'AERT' as SCAC,
	'AERO FULFILLMENT SERVICES' as ShipFromName,
	'' as BillToLine1,
	'' as BillToLine2,
	'' as BillToLine3,
	'' as BillToLine4,
	'PREPAID' as PaymentTerms,
	'2018-12-12 06:26:53.000' as DepartureDate,
	'2018-12-12 06:26:53.000' as DeliveryDate,
	'1900-01-01 00:00:00.000' as TransmitDate,
	0 as ResendFlag,
	'' as Custom1,
	'' as Custom2,
	'2018-12-11 17:19:57.697' as AddDate,
	'wmwhse1' as AddWho,
	'2018-12-12 06:28:35.803' as EditDate,
	'wmwhse1' as EditWho


insert into scprd.wmwhse1.LTLShipmentPallet (ShipmentKey,PalletKey, Consign, Zip, AddDate, AddWho, EditDate, EditWho)
select
	'0000080397' as ShipmentKey, -- shipmentkey that matches the one auto generated in ltlshipment
	'42336' as PalletKey, -- dropid from infor or whatever that put in 
	'THE ART OF SHAVING-ECOMMERCE' as Consign,
	45014 as Zip,
	'2018-12-12 06:33:18.500' as AddDate,
	'wmwhse1' as AddWho,
	'2018-12-12 06:33:02.497' as EditDate,
	'wmwhse1' as EditWho

with both of those records created in additional to manifest this sent out on 945

_________________________________________________________________________________________________________
/*							ATP-12789 
							Set up Child meter for Coty using fedex with smartpost
							1/7/19 - 2-

Hi Doug,

I am working on getting Coty set up with a child meter to ship via FedEx (ticket   ATP-12789 REVIEW  ).
Currently I am trying to figure out how to acquire a MeterNumber for this account; Filipe told me to ask you about this. Is something you can set up? Do you need anything else from me to get this created?

Thanks,
Cory Brown

from cory right before ticket was reassigned to me.

via Jean in email today
she sent PO and RWO to CLS and I believe we are waiting on this before I can work on this?

child meter acc # from fedex is:
when doug has new client he asked fedex for new child metere number to track
and then this is sent to us for implementation.

TESTING SHIPPER
create order in UAT web nav
make ASN for whatever item going to use. make sure to receive into and actual location
that isnt stage
once that is recvd you can work the order normally in infor

afterwards go into devtms01:6000 and print using caseid
-- may need configure if using infoship from own system. meaning each machine running
-- infoship needs to manually
to test label


_________________________________________________________________________________________________________
/*							ATP-13014 
							Marksmen freight rate sheet missing military 99
							1/8/19 - 

more from Doug S
there will be lots of freight rate changes upcoming with new Fulfillments so be ready

for this ticket it looks like it may just be missing a line or missing a connection to 

sub process
summary and details for order incident

detail gets fed into csv that gets attached.
actual stored proc - messages in code in own table orders_errorcode 
so we can add more logic and another error code record in this table later

summmary takes every unique msg and concats.
report_order_incident

looking at james documentation for freight rate set up
First, take a look at the Fulfillment_Freight_Billling table.
SELECT TOP (1000) * FROM [ENTERPRISE].[dbo].[Fulfillment_Freight_Billing]
This table holds data for the 'costplus' rates for each ship method for each fulfillment.
 We will need to insert new records into this table for the new rates we are setting up. 

example insert:

insert into [Fulfillment_Freight_Billing] 
select 
1163
,'FREIGHT_FEDX'
,[servicetype]
,[costplus]
,[nomarkup]
,getdate()
,'Cory'
,getdate()
,'Cory'
FROM [ENTERPRISE].[dbo].[Fulfillment_Freight_Billing]
where fulfillment_id = 1161
and carrier = 'FREIGHT_FEDX' 

 Now we need to insert a record into the [FreightCarrierRate] table. 
This table joins fulfillment_id's with records from the FreightRate and FreightCarrier tables. 

example insert:

insert into freightcarrierrate 
select 1163,2,6 
Finally, we just need to update the bill_freight field in fulfillment table record for this fulfillment. The value needs to match the rate_id value that you used in the previous step. 
update fulfillment set bill_freight = 6 where fulfillment_id = 1163

another freight doc:
https://aerofulfillment.atlassian.net/wiki/spaces/STCT/pages/31784966/Freight+Management



_________________________________________________________________________________________________________
/*							ATP-13735 
							Can not download FedEx invoice
							1/7/19 - 1/10/19
------------
fedex.com
DRC

worked with filipe after not seeing the issue myself. seems very slow but filipe was able to
queue a download

options are all in this part of site and guy didnt sound like he could
tell us we can use FTP or not. 

contacted tech support and they pointed me to their developer resource center which 
had 3rd party software and services besides their direct web services. 
the guy i spoke to on the phone wasnt very technical sounding so 
i couldnt get very far with what our options could be for trying to set our FTP up with them

_________________________________________________________________________________________________________
/*							ATP-13757 
							Please force ship order for AOS
							1/8/19 - 1/9/19

talked to heather
basically there may be a small issue or a voice issue with orders
getting stuck in packed status even though we have no errors showing
that it is stuck at all

however i verified that nothing was missing and everything looked fine.
and then shipped the order and closed ticket.
shes opening several tickets like this under matts instruction and
Archana had the other one.

_________________________________________________________________________________________________________
/*							ATP-13749 
							Unable to add new customer
							1/9/19 - 1/9/19

updated permissions for jennifer in CMG. she has 3 accounts for some reason. 
walked j2 through this
_________________________________________________________________________________________________________
/*							ATP-13787 
							when in back end nav cant open order view report
							1/9/19 - 1/9/19
1/9 looked for the issue she claimed was occurring, needed a little more digging.
order view vay
i edited this in october
seems opening this through windows nav is broken
could be related to 14556 3/28/19

_________________________________________________________________________________________________________
/*							ATP-13624 
							cycle counts / adjustments
							1/8/19 - 1/10/19
helping j2 with proc / query for pulling proper cc detail data

with this updated stored proc
-- =============================================
-- Author:		James Cardwell
-- Create date: '2017-08-29'
-- Description:	Cycle Count detail report – SKU, location, date, qty, results, location accuracy %, absolute qty variance and Percentage
-- testing:
-- exec mason.[dbo].[pr_Report_CDL_CycleCountDetail] 'IRE', '02-01-2018','01-09-2019'
-- =============================================
ALTER PROCEDURE [dbo].[pr_Report_CDL_CycleCountDetail]
	@storerkey as varchar(5),
	@startdate as datetime,
	@enddate as datetime

AS
BEGIN
	
	SET NOCOUNT ON;

    
	select 
c.SKU, 
c.loc, 
c.adddate, 
c.qty, 
c.sysqty,
abs(c.adjqty) as adjqty, 
case when ABS(ADJQTY) <= SYSQTY then 100- (ABS(ADJQTY)/case when SYSQTY = 0 then 1 else SYSQTY end)*100 else (SYSQTY/ABS(ADJQTY))*100 end 'variance %' from wms_CCDETAIL_ALL c (nolock)

where c.storerkey = @storerkey
and ADDDATE between @startdate and @enddate

--- then we found out ccdetail_all isnt designed properly to do this 
(the union pulling scprd arc data)
 because its only pulling 181 records for 45 days i believe

union all
select
ccd.SKU, 
ccd.loc, 
ccd.adddate, 
ccd.qty, 
ccd.sysqty,
abs(ccd.adjqty) as adjqty, 
case when ABS(ADJQTY) <= SYSQTY then 100- (ABS(ADJQTY)/case when SYSQTY = 0 then 1 else SYSQTY end)*100 else (SYSQTY/ABS(ADJQTY))*100 end 'variance %'
FROM            [SCPRDARC].[wmwhse2].[CCDETAIL] AS ccd WITH (nolock)
where ccd.storerkey = @storerkey
and ADDDATE between @startdate and @enddate

investigated by simply right clicking orders_all view then design
seeing its unioned to scprdarc

and checked ccdetail_all and it isnt unioned

_________________________________________________________________________________________________________
/*							ATP-13750 
							Please add robertvasak@discover.com	to weekly discover
							inventory report dist list - billable
							1/9/19 - 1/10/19

title of report in system is Mason_DF_InventoryListxUOM

jeff-net = Report runner
either assigned in windows nav or jeff-net but per james 
he would know if it was jefnet because he would get the emails also

GO TO AFS-REPORTS server in RDP

after giving james title and he searched email he found it
it is jeff-net
how to nav jeff-net
login with administrator pw in keepass
click open in top menu bar
find fulfillment or report style
in this case its an 8am monday only report open this
in this folder we find our MASON DF inv report 
double click it to open once open in destination at top you can see all emails
it is going to. here we can add new email separated from other emails by semicolon
at bottom click 'okay' to save and update and it closes this menu and 
shows updated in status/message
lastly make sure we click save in top menu bar just to save again in folder
should give a confirmation of the exart report updated

_________________________________________________________________________________________________________
/*							ATP-12309 
							Is waving criteria set up to autowave excluding Boost employee orders
							 all month long then one autowave for boost employee orders on the 
							 1st of each month for Onnit? Is it tested?
							1/9/19 - 1/10/19

helping J2 with his onnit waving criteria ticket 
atp12309 
where do we determine waving criteria per fulfillment?

not in nav. or SQL procs
per james this is under scheduler in infor
and scheduled jobs

will have to create 2 jobs 
need to tell infor somehow that job 1 runs like this sql

select o.cost_center,*
from lebanon.dbo.orders o (nolock)
left outer join lebanon.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
where w.STORERKEY = 'ONN'
and o.cost_center like '%boost%'
and o.add_date > '2018-09-13 08:59:10.000'

-- only 1st day of month and only 1 autowave
-- job 2 runs whole month but excludes all boost

select o.cost_center,*
from lebanon.dbo.orders o (nolock)
left outer join lebanon.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
where w.STORERKEY = 'ONN'
and o.cost_center <> like '%boost%'
and o.add_date > '2018-09-13 08:59:10.000'


-- helping joshjosh on update to proc. need to add mfg lot and stop ship date
SSd is from inventory stop ship joined on storerkey
cant find mfg lot yet.



_________________________________________________________________________________________________________
/*							ATP-13609
							fix 4th ship station in mason
							1/3/19 - 1/11/19
-- ship station testing. changing ports and testing ship station 4 cpu at 3
aeroh0tw4v3!
#;TiL15qg magic locAL admin pw
testing to see how connection works on ship 3 and then going to 4.
dms server name is dms shipments?
now trying to run repair tools va infoship installer.
didnt work
completely removing infoshpi and starting fresh
still didnt work. may need to actually switch the ports that infoship is connecting to?

error is unable to connect to DMS server [] error:[2003] DMS server cannot be found 
trying to enter servername afstms01
error for this server is error:[2012] The workstation has been denied access to the server.
confirm DCOM Config settings are correct on the server
Distributed Component object Model is a set of microsoft concepts and program interfaces 
in which client program objects can request services frm server program objects
on other computers in a network
need to do run in cmd
Dcomcnfg.EXE
enter in administrator pw (currently not working was disabled and now saying bad pw or unknown user)

designate port via printer set up and also in infoship.
afstms01:6000 and make sure ports match
give generic zebra name as printer
set to generic / text and generic as brand/model

make sure to add patch files

ping afstms01

telnet afstms01:6000

could not open connection
 may need to call netgain

 they were supposed to keep this port open

 tool to auto trace map to see where it blocks

 need to install something to do this?
working with ben type in IP.port in info ship
doing traceroute 
masship pw?

afstms01 192.168.22.106
looks like firewall issue through peak10 potentially
set up manual IP 
create ACL on router
machine ip 192.168.0.17 that allows access on port 6000
same Dgateway as 192.168.0.15 ship station 3

going to wait for vendors to set up ACL on router then can test again
-- access control list
	- set of rules that controls network traffis and mitigates network attacks. more precisely,
	 the aim of the ACLs is to filter traffic based on given filtering criteria on a router or
	  switch interface

what vlan is 3 on and what vlan is 4 on?
or use diff port in IDF can depend on subnet

apparrently peak was able to get hits on port 6000?

bae or peak helped append a firewall policy/rule we had already
to include the new port connection

_________________________________________________________________________________________________________
/*							ATP-13806
							IRD and FW notifications in NAV saying cant subscribe
							but clients are receiving emails from inv adjustments
							1/10/19 - 1/11/19

could be in jeff-net report. found 1 with FW called Found Stock. which is kind of inventory related.
under daily 144 am

but more than likely through magento or windows nav


_________________________________________________________________________________________________________
/*							ATP-13692
							The following orders have not sent the GI's back to SKII LK0000010015
							1/09/19 - 1/14/19

sk-2 or sk-II is part of learning works and the boomi job they are under is 3PL
checking boomi process of 945 to see if these went out yet

#BSY 4/15/19 see atp-14732

_________________________________________________________________________________________________________
/*		week of 1/14/19 
must do 1/14: clear up as much of sprint as possible
atp-13436 james thinks is generally a bug and should just be the simple change
to sequence in general. but may have to estimate rest of this ask for CX
because it could be more in depth. should test the change and push to prod.
will ask james on this process.
must also try to get back to mason to try to finish ship station and start on 5th
and diagnose ultipro kiosk. -- update going with Fil and j2 tuesday 10am
also believe there is work to be done for coty atp-12789

and doug needs to be able to email from nav in order for email printing to be effective
rest of week;
more work on varta 945

my up
AERO005040
CNP%

_________________________________________________________________________________________________________


_________________________________________________________________________________________________________
/*							ATP-13828
							KB% showing partially shipped but all lines picked complete and shipped complete
							1/09/19 - 1/14/19
line 4 definitely wasnt shipped complete in infor. was part shipped even though shows 12 / 12 shipped
issue is that it was 2 separate picks 1 of 10 other of 2. and someone may have shipped
before other 2 were picked

 very strange error. looks like temp6 user may have picked item 13551 incorrectly or
 this was shipped during picking of this last item and split the pick detail?

 

_________________________________________________________________________________________________________
/*							ATP-13829
							ASN from pure are not in infor acknowledged on 1/8 at 10:56a and 4:55am
							control files are 50621 and 50636 confirm recvd 
							and put in infor
							1/14/19 - 1/14/19

these were imported as ASN before the items were imported into system by client

API_RESPONSE table in wmwhse1
boomi job of listener and 943 ASN/PO import

checked the dates of ASN/PO import against the skus add date


_________________________________________________________________________________________________________
/*							ATP-13823
							Picking forecast update: add column 
							1/09/19 - 1/14/19

waves get printed after waver goes into system and waves then batches orders
based on shipmethod
printing the actual waves comes after and gives pickers the tasks to start


-- notes 1/15/19 query for jeffnet reports?
-- how to create report that says if a wave printed?
-- on ltl manager dropid / palletkey process
-- -- the cases must get a sticker that have a palletkey like 00040172 or 00046860 and then scanned
-- -- after this number is entered into infor? then it will appear in ltl manager


_________________________________________________________________________________________________________
/*							ATP-13816
							Send ASN to vayyar for va 67066 and va 67068
							1/15/19 - 1/15/19

one order had to have outbound capture data aka serialnumlong added
used Create_CatchData_VAY

basically use the get in vay ltl ship conf but add the update and externorderkey in where
also used updates since these are ltl to ASN field
--update pd
	set asn = '#numbergiven'
		edistatus = 0
	from ...
	where ...
	and externorderkey = 'VA0000067066'

made sure it sent on vay 945 boomi job

_________________________________________________________________________________________________________
/*							ATP-13823
							Add serial number and ship amazon order VA0000067067
							1/15/19 - 1/15/19

order had to have outbound capture data aka serialnumlong added
used Create_CatchData_VAY

made sure it sent on vay 945 boomi job

_________________________________________________________________________________________________________
/*							ATP-13834
							RA0000043548 will not let me ship complete
							1/15/19 - 1/15/19

this order wasstuck possibly due to allocation issue. per infor 
all items were picked at same time? per james we can update
then run fix allocation
because none of the pick detail records were in pickto

_________________________________________________________________________________________________________
/*							ATP-13832
							3 sk-II orders wont ship already left building
							1/14/19 - 1/15/19

shipped fine in infor but the ship confirm process probably wont run because they dont have dropids
after i had shipped them i guess they were able to update in ltl manager? because earlier they
didnt have dropids but now it looks like they do


_________________________________________________________________________________________________________
/*							ATP-13825
							RA41251 RA41257 RA41272 case has no valid manifest record 
							no shipping data could be found
							1/14/19 - 1/15/19
RA0000041257 or
RA0000041251 or
RA0000041272

script to insert / create manifest records from Archana from Josh

use lebanon
go


	declare @AeroOrderNbr as varchar(30)
	  , @CaseID as varchar(30)
	  , @SourceCaseID as varchar(30) = '0071047710' -- caseid with existing manifest record to pull from
	  , @Tracking as varchar(30) = 'No Tracking'

	/* Order: RA0000041593
	 ('RA0000041257',
	'RA0000041251',
	'RA0000041272')
	*//*
	set @AeroOrderNbr = 'RA0000041593' -- order needing manifest record
	set @CaseID = '0071139955'; -- caseid needing manifest record

	select * from manifest where caseid = @CaseID

	INSERT INTO Manifest (trackingnumber, caseid, order_primary_reference, void, weight, charge, sur_charge, packages, bol, carrier, service, thirdpty, cod_package_flag, consignee_residential_flag, saturdaydelivery_flag, oversize_flag, bill_flag, 
							 signature_flag, aro_consignee_billing_flag, aro_freight_collect_flag, tran_date, ship_date, status, add_date, edit_date, add_who, edit_who, billing_period, billing_status, orders_id)
	SELECT        @Tracking AS Expr1, @CaseID AS Expr2, @AeroOrderNbr AS Expr3, void, weight, charge, sur_charge, packages, @AeroOrderNbr AS Expr4, carrier, service, thirdpty, cod_package_flag, consignee_residential_flag, 
							 saturdaydelivery_flag, oversize_flag, bill_flag, signature_flag, aro_consignee_billing_flag, aro_freight_collect_flag, tran_date, ship_date, status, GETDATE() AS Expr5, GETDATE(), 'ArchanaT' AS Expr6, 'ArchanaT', billing_period, 
							 billing_status, orders_id
	FROM            Manifest AS M1
	WHERE        (caseid = @SourceCaseID)
	
	select * from manifest where caseid = @CaseID

works to adjust manifest data from an existing manifest need to rework and expand on this
to make it work for either missing or existing manifest records


_________________________________________________________________________________________________________
/*							ATP-13841
							Customers receiving a message "error in payment" when trying to place orders
							on e store. user tried company credit card
							1/14/19 - 1/17/19
original error :
"The error response was ERROR IN PAYMENT (8226FD632247D9E0531D588DOA91B1) COULD NOT BE FOUND"
on cybersource site i see: Invalid Request Data 
the subscription (8226FD632247D9E0531D588D0A91B1) could not be found 

James believes this site is missing the nav menu item 'Reoccuring Billing'
we searched through the search for the transactions and kind of see the issue where there is an error
code.

response to ticket from cybersource
"In order for me to enable "Recurring Billing", you'll need to reach out to your Account Manager"
 and have this billable service added to your contract. 
Once this is done please let me know and I'll then confirm with our SalesOps team, and get it enabled for you.

Also please review this dev guide and on page 12, let me know which subscription ID format you are going to want.

http://apps.cybersource.com/library/documentation/dev_guides/Recurring_Billing/SO_API/Recurring_Billing_SO_API.pdf

Please let me know when you've talked to your Account Exec and had this added to your contract."

testing turning off sureacceptance in UAT. use web nav uat to test order and try to make a payment
without sureacceptance on. doesnt work

oCreditCard("ics_applications") = "ics_pay_subscription_create"
                oCreditCard("currency") = "USD"
                oCreditCard("merchant_ref_number") = IIf(UseProfiles, oOrdRow("customer_id").ToString, 
				oOrdRow("primary_reference").ToString).ToString
                oCreditCard("recurring_frequency") = "on-demand"
                oCreditCard("recurring_payment_amount") = 0.ToString
                'Translate the Aero Payment Type into Cybersource Card Types and pad with leading zero's
                oCreditCard("card_type") = CInt(CybersourceCardTypes.Parse(GetType(CybersourceCardTypes),
				 CType(payrow.Item("payment_method_id"), PaymentType).ToString)).ToString.PadLeft(3, "0"c)

in test it is set up with recurring billing.
this is a requirement of nav system				 

_________________________________________________________________________________________________________
/*							ATP-13860
							urgent: RF guns at mason having connection issue/ stating
							'nothing to do' when work should be available
							1/16/19 - 1/17/19
Need to troubleshoot at mason to see what is occurring first hand

this was due to workers logging in with their fairfield users that were at mason helping
need to find the users and add mason to their roles
_________________________________________________________________________________________________________
/*							ATP-13833
							RA42329 has left the building i believe i entered a ticket before
							this but still not shipped
							1/16/19 - 1/17/19
shelf life issue holding up 1 line. didnt update looks like ops resolved

-- notes for fixing double printing labels from filipe
-- infoship - admin - docs - package and remove dupe



_________________________________________________________________________________________________________
/*							ATP-13629
							we need email ClientSupport@aerofulfillment.com to go to Chris Upton
							Instead of Kim Meyers
							1/16/19 - 1/17/19
jeff-net or windows nav?


printer issue for doug. networking printer remains an issue. purely using wifi from printer seems
unreliable and i cant maintain it. going to try hardwiring and somehow forwarding that to network?
how will this create a wireless or network connection? as long as the printer
touches a hard drive or network directly the computer tells it to print when connected

-- sprints by democracy? has to have voice of reason per business needs
-- effective sprint methods. 

-- when testing orders in UAT with new boomi jobs
-- if it gets shipped in infor but stuck as active in nav
-- need to run line item update job in boomi
-- however UAT has bad data so this job doesnt work and you need to instead
-- use this query
DECLARE @start datetime, @cnt int
SET @start = getdate()


--UPDATE TOP (1500) lt
UPDATE TOP (2500) lt
	SET [status] = case 
			when od.status >= '95' then '9'
			when od.status >= '17' then '5'
			--when lt.status = '0' then '1'
			else lt.status end,
		qty = case 
			when od.status >= '95' then od.shippedqty 
			else lt.qty end,
		reasoncode = case 
			when od.status >= '95' then case 
				--10/19/2012 shortshipreason='7'->CANCELED
				when isnull(od.shortshipreason,'')='7' then 'C' 
				else rtrim(od.susr4) end
			else lt.reasoncode end
	FROM Lineitem_Transaction lt
	INNER JOIN wms_ORDERDETAIL od with (nolock)
		ON lt.order_reference = od.externorderkey
			AND lt.line_number = od.externlineno
	WHERE ((od.status >= '95' and lt.status < '9') or
		  (od.status >= '17' and lt.status < '5'))
		  --and lt.fulfillment_id = 1162
		  --and lt.lineitem_id = 190159748
			and od.externorderkey in ('RA0000015658','RA0000015656')
			--and lt.orders_id = 31713639
		--or (lt.status = '0')


SET @cnt = @@rowcount
IF @cnt > 0
BEGIN
	INSERT INTO Process_Log
	SELECT 'WH1', getdate(), null,
		'UpdateLineitems',
		null, 'SUCCESS',  'Seconds to run=', datediff(ss,@start,getdate()), null,
		@cnt, null
END
-- end of order testing in uat/nav/infor with infor being shipped but nav stuck


_________________________________________________________________________________________________________
/*							ATP-13851
							order stuck in submitted status please release
							1/17/19 - 1/18/19

-- from anne DO0000200871 is stuck in Submitted from 1/8. Please release.

-- check order
select *
from mason.dbo.orders o (nolock)
left outer join mason.dbo.wms_orders_all w  (nolock) on w.EXTERNORDERKEY = o.primary_reference
left outer join mason.dbo.wms_PICKDETAIL_ALL pd (nolock) on pd.ORDERKEY = w.ORDERKEY
left outer join mason.dbo.wms_taskdetail td (nolock) on td.caseid = pd.caseid
left outer join mason.dbo.Lineitem l (nolock) on l.orders_id = o.orders_id
where o.customer_reference = '100022027'
--o.primary_reference in ('DO0000200871')

-- check line item if its in inv and has QTY
select *
from mason.dbo.inventoryedit (nolock)
where item_id = '231426'

-- check to see if its in batch
select *
from mason.dbo.Orders_Batch where orders_id = '38438958'

boomi job didnt pick it up on add date. per james no apparent root cause


_________________________________________________________________________________________________________
/*		week of 1/21/19 
vvvvvvvvvvvvvv clearly barely touched last weeks sprint CANNOT DROP SPRINT
must do 1/14: clear up as much of sprint as possible
atp-13436 james thinks is generally a bug and should just be the simple change
to sequence in general. but may have to estimate rest of this ask for CX
because it could be more in depth. should test the change and push to prod.
will ask james on this process.
must also try to get back to mason to try to finish ship station and start on 5th
and diagnose ultipro kiosk. -- update going with Fil and j2 tuesday 10am
also believe there is work to be done for coty atp-12789
^^^^^^^^^^^^^^ CANNOT DROP SPRINT

and doug needs to be able to email from nav in order for email printing to be effective 
-- update on above from last week ^^^^^^ printer not networking through RDP correctly
-- how the heck can i do this?
rest of week;
more work on varta 945							


_________________________________________________________________________________________________________
/*							ATP-13566
							need C S D for check digits for new locs
							1/21/19 - 1/22/19

export locs that are already in infor that appear to match type like BULK

paste over with new locs and some loc specifics if needed

verify all locs are represented and then run the selects for check digits

ctrl shift c results then paste into excel and send to or attach in ticket


_________________________________________________________________________________________________________
/*							ATP-13909
							Stuck ONN orders
							1/22/19 - 1/22/19
matt claims they did everything they know to do correctly and somehow they are getting stuck
in allocated status

ON0000031040
ON0000030991
ON0000030989
ON0000030987
ON0000030982
ON0000030944
ON0000030929
ON0000030868
ON0000030841
ON0000030805
ON0000030756
ON0000030736
ON0000030694
ON0000030629
ON0000024012
ON0000000432

select *
from lebanon.dbo.orders o (nolock)
join lebanon.dbo.wms_orders_all w (nolock) on w.EXTERNORDERKEY = o.primary_reference
join lebanon.dbo.wms_PICKDETAIL_ALL pd (nolock) on pd.ORDERKEY = w.ORDERKEY
where o.primary_reference in 
('ON0000031040',
'ON0000030991',
'ON0000030989',
'ON0000030987',
'ON0000030982',
'ON0000030944',
'ON0000030929',
'ON0000030868',
'ON0000030841',
'ON0000030805',
'ON0000030756',
'ON0000030736',
'ON0000030694',
'ON0000030629',
'ON0000024012',
'ON0000000432')

checking logs for API inbound docs

verifying the issue that is occurring for these orders

ON0000031040 go to \\afsutil01\c$
then go to sc.api then logs and open most recent and can CTRL + F and search by prim ref
find 2nd occurrance of prim ref and it should be next to the error

ON0000030929 go to inbound api feed logs to see exactly what data it had when it came in
file explorer \\PDweb01\e$ then SC.api then logs and then find the add date and CTRL + F use
cust ref to search by and find what data was in phone number. in this case was entirely blank
was later updated and was too late because boomi was already told phone was an issue
and that it shouldnt pick this up

here are the results of the issues

select top 100 * 
from lebanon.dbo.manifest (nolock)
where order_primary_reference in 
('ON0000031040', -- phone missing
'ON0000030991', -- has manifest
'ON0000030989', -- mfg country blank
'ON0000030987', -- has manifest
'ON0000030982', -- has manifest
'ON0000030944', -- mfg country blank
'ON0000030929', -- phone missing
'ON0000030868', -- phone missing
'ON0000030841', -- has manifest
'ON0000030805', -- phone missing -- ALSO HAS VOID FLAG DONT TOUCH
'ON0000030756', -- mfg country blank -- ALSO HAS VOID FLAG DONT TOUCH
'ON0000030736', -- mfg country blank
'ON0000030694', -- mfg country blank
'ON0000030629', -- mfg country blank
'ON0000024012', -- arch
'ON0000000432') -- has manifest

going to update dmsserver.dbo.shipments to set the hold flag to 0 so boomi will
pick these up and allow to be shipped


--update s
 set shipmenthold_flag = 0
 --select *
 from dmsserver.dbo.shipments s(nolock) where shipper_shipment_reference in 
 ('ON0000031040','ON0000030989','ON0000030944','ON0000030868','ON0000030694','ON0000030929','ON0000030736','ON0000030629')

-- using above i actually had ON0000030756 and ON0000030841 in the ship refs but this is where
-- i noticed the voids flags and james said not to touch. these can be put in void due to
-- shipment cancel, ship method change, or overall mistakes.
-- not sure what to do with remaining 2 then. i guess inform matt of void flag

-- query filipe used for onnit orders issues

select
convert(date,wo.order_date) as OrderDate, wo.primary_reference, wo.customer_reference,o.ORDERKEY, wo.ship_method_id,
od.ORDERLINENUMBER, OD.SKU,od.SHIPPEDQTY,OD.OPENQTY,od.QTYPICKED,
wo.cost_center, wo.order_status as NavStatus, wo.ship_date, pd.caseid, m.trackingnumber,
o.c_PHONE1,
case
    when o.STATUS is null then 'not in infor'
    when o.status=02 then 'received'
    when o.STATUS=95 then 'ShipComplete'
    when o.status=92 then 'Part Shipped'
    when o.status=68 then 'pack complete'
    when o.status=61 then 'in packing'
    when o.status=52 then 'part picked'
    when o.status=55 then 'pick complete'
    when o.status=29 then 'to be picked'
    when o.status=17 then 'allocated'
    when o.status=9 then 'not started'
    else o.status
end as inforOrderStatus,
case
    when pd.STATUS = 5 then 'picked'
    when pd.status = 9 then 'shipped'
    when pd.status = 6 then 'pack complete'
    when pd.status = 1 then 'released'
    when pd.status is null then 'not waived'
    else pd.status
end as lineStatus,
wd.WAVEKEY, convert(date,wd.ADDDATE) as WaveDate,
pd.EDITWHO
from ENTERPRISE.dbo.Nav_All_Orders wo
left join SCPRD.wmwhse1.ORDERS o on o.EXTERNORDERKEY=wo.primary_reference
left join scprd.wmwhse1.ORDERDETAIL od on o.ORDERKEY=od.orderkey
left join SCPRD.wmwhse1.WAVEDETAIL wd on o.ORDERKEY=wd.ORDERKEY
left join scprd.wmwhse1.PICKDETAIL pd on pd.ORDERKEY=od.ORDERKEY and pd.ORDERLINENUMBER=od.ORDERLINENUMBER
left join lebanon.dbo.Manifest m on m.order_primary_reference=wo.primary_reference and pd.caseid=m.caseid
where order_status <> 'Shipped'
and order_status <> 'canceled'
and order_status <> 'skipped'
and order_status <> 'error'
and order_status <> 'savedcart'
and wo.parent_short_name='ONN'
--and wo.cost_center <> 'CONTINUITY'
and wo.cost_center <> 'Office shipment'
and wo.cost_center <> 'hard premium'
and wo.cost_center <> 'sip single'
and wo.cost_center <> 'sip double'
and o.status > 61
order by convert(date,order_date), wo.customer_reference, od.ORDERLINENUMBER

______________________________________________________________________________________________________________________
-- new task from josh -------- RF gun to facilitate cycle count inventory lot validation
-- work with johnetta on infor cycle count for inventory
-- ex 10 10 80 = 100 and infor currently sees that as no variance or nothing wrong
-- we need to go incrementally as many lots as it takes per loc
-- 1st lot for loc --- 

-- test try using UAT trident an infor rf emulator
-- see if we use option 8 or 9 in menu


_________________________________________________________________________________________________________
/*							ATP-12467
							report id 2929 needs PO added
							SPL
							1/21/19 - 1/22/19

05-004105-1 is example

this is the PO bound to PO table scprd.wmwhse1.PO as pokey
doesnt look like any good way to join this to orders?

already put the cust ref in yesterday by mistake because they look similar but thats the outbound PO
and PO inbound looks like 05-004105-1

either need to find proper join to work or this cannot be achieved this way
PO first 
then create asn and add PO to asn / receipt

end of the day james is right it needs to be in the receipt table 

Select
	'Consign' = '',
	'SKU' = i.primary_reference,
	'Desc' = i.short_desc,
	'CIC Code' = isnull(i.reference_2,''), 
	'DB Code' = isnull(i.reference_3,''),
	'Customer Order ID' = '', 
	'DB Order ID' = r.pokey, -- #BSY 1/23/19 PO# is pokey from receipts table in scprd?
	'Aero Order Date' = '', 
	'Transaction Type' = CASE WHEN it.toloc like 'RETURN%' THEN 'Return' ELSE 'Receipt' END,
	'Tracking' = '',
	'Qty' = SUM(it.qty / Case when isnull(i.[@UomQty],0) = 0 THEN 1 ELSE isnull(i.[@UomQty],1) END),
	'QTY Per UOM' = i.[@uomqty],
	'Transaction Date' = Convert(date, it.EFFECTIVEDATE)
from inventoryedit i (nolock) 
	join wms_itrn_ALL it (nolock) on i.primary_reference = it.sku  
	right join lineitem li(nolock) on li.item_id = i.item_id
	right join mason.dbo.wms_RECEIPTDETAIL_All r(nolock) on r.receiptkey = it.receiptkey

where i.fulfillment_id = '1155' 
	AND ((it.trantype = 'DP' AND it.sourcetype <> 'ntrTransferDetailAdd') OR (it.trantype = 'AJ' AND it.sourcetype = 'ntrAdjustmentDetailUnreceive'))
	and it.EFFECTIVEDATE between '2018-12-23 20:58:13.000' and '2019-1-23 20:58:13.000'
	and i.primary_reference <> '99999'
	
group by i.primary_reference, i.short_desc, isnull(i.reference_2,''), isnull(i.reference_3,''),r.pokey, it.toloc, i.[@UomQty], Convert(date, it.EFFECTIVEDATE)


sourecekey = receiptkey + receiptlinenumber *** MAJOR FIX 
-- ADD THIS TO JOINS

_________________________________________________________________________________________________________
/*											ATP-13924
												LK10365 this order is stuck in part shipped status has left building
												1/22/19 - 

one line still has 2 open qty. why didnt pickers ship this? was it meant to be short shipped?
if so they need to zero this out. afterwards this should ship fine. otherwise may be a little stuck
due to db blocking.



_________________________________________________________________________________________________________
/*											ATP-13920
							MBPAS1079 96 left (not currently on hold) Looks like it could be pre allocated
							and won’t let me move lot 0000275997 to Hold. see error below Infor Global Solutions
							 Hold caused by move is disallowed since inventory is currently allocated or picked or pr
												1/22/19 - 
ran fix allocations because correct qty are in infor 
using wms_lotxlocxid and sku MBPAS1079
will see if it works next time she tries to move.

do preallocations show as allocated qty in infor move screen?

james thinks there isnt actual qty available in the amount she thinks
why cant this say there isnt x available would you like to use y remaining for this move?

double checking on 2/18 - 2/19/19


_________________________________________________________________________________________________________
/*										ATP-13792 and atp-13612
											printer for doug needs to connect to RDP afsterm01
											12/28/18 - 

Network printers notes
-	Dougs printer isn’t going to work because of the port and driver config. Need to go in and add new port 
with an open IP so it can reach the network through port using this dedicated ip. It is not static however so 
the ip lease could end and need to be re configged every time the printer is power cycled. Itll also should need to
 be set up in rdp term server same way mentioned above but should be done in addition to it being added locally.
  DHCP instead of static
-	In general most of our network printers are on the print server which is why they work in RDP servers

if printer is already set up go in to properties
- ports
	- now click add port
		- new port - select standard tcp/IP port 
		- enter ip address as an available IP addres then add a random port name like IPadd_X
		- continue set up

other printer issue
-- i didnt set jennys computer up to printer on print server that i didnt know about
-- aero-ff-fp is server name not sure how else to add
192.168.4.124

Network printers notes
-	Dougs printer isn’t going to work because of the port and driver config. Need to go in and add new port with 
an open IP so it can reach the network through port using this dedicated ip. It is not static however so the 
ip lease could end and need to be re configged every time the printer is power cycled. Itll also should need to
be set up in rdp term server same way mentioned above but should be done in addition to it being added locally.
 DHCP instead of static
-	In general most of our network printers are on the print server which is why they work in RDP servers
-- JUST LEARN TO SET UP ON aero-ff-fp print server - may not work for mason

can try remoting into print server using rdp and add printer in there

_________________________________________________________________________________________________________
/*										ATP-13888
											IRD is getting ship confirms for prod orders
											1/22/19 - 2/10/19

issue is that this was from old boomi and has email confs built into it. which includes prod orders.
need to go in to SQL where clause and just filter out prod order on o.order_type 

annual sub. todd needs to not use robs acc. set up his account better to have all programs he uses
so we can close robs account keep list of all those systems. 

-- used this query to test. unfortunately there is nothing i can really base this on for test data
-- because with or without the change theres only 126 total orders which wouldnt be filtered out
-- either way.
todds pc ip 192.168.0.192 is mas-robs
used to be robs new pc
masdp01 is robs old pc

--Production version with backorders--------->>>>
SELECT trans_id = ft.trans_id,
	o.primary_reference,
	o.customer_reference,
	o.order_date,
	o.ship_date,
	o.order_type,
	order_status = case 
		when o.order_status in ('ERROR','CANCELED','SKIPPED') then 'CANCELED'
		when not exists (select 1 from lineitem(nolock) where orders_id=o.orders_id and qty_shipped>0) then 'BACKORDERED'
		else 'SHIPPED' end,
	shipmethod = sm.description,
	o.consign,
	o.ship_attention,
	o.ship_address_1,
	o.ship_address_2,
	o.ship_city,
	o.ship_region,
	o.ship_postal_code,
	o.ship_country,
	o.phone,
	o.email,
	o.ship_chg,
	--CASEID section------------------------------------------------
	caseid = isnull(pd.caseid,''),
	productreference = isnull(pd.sku, l.item_primary_reference),
	qty_shipped = convert(int,(isnull(pd.qty,0) / isnull(pk.units,1))),
	line_status = case 
		when l.line_status in ('ERROR','CANCELED','SKIPPED') then 'CANCELED'
		--we evaluate this case by case
		when l.line_status='SHIPPED' and isnull(pd.caseid,'')='' then 'BACKORDERED'
		else 'SHIPPED' end,
	lineid = convert(int,isnull(lx.flexfield1,l.line_number)),	--client supplied line number
	l.line_number,
	trackingnumber = isnull(m.trackingnumber,'')
FROM Orders o (nolock)
INNER JOIN Fulfillment_Transaction ft(nolock)
	ON o.orders_id = ft.trans_key01
--INNER JOIN Orders_Batch ob(nolock)  --all orders, not just feeds
--	ON o.orders_id = ob.orders_id
--INNER JOIN Batch b(nolock)
--	ON ob.batch_id = b.batch_id
INNER JOIN Lineitem l(nolock)
	ON o.orders_id = l.orders_id
INNER JOIN Lineitem_Flexfields lx(nolock)
	ON l.lineitem_id = lx.lineitem_id
INNER JOIN Inventory i(nolock)
	ON l.item_id = i.item_id
INNER JOIN Ship_Method sm (nolock)
	ON o.ship_method_id = sm.ship_method_id
LEFT JOIN Inventory_PackDetail pk(nolock)
	ON i.packkey = pk.packkey AND i.default_uom = pk.uom
--WMS section-----------------------
LEFT JOIN wms_ORDERDETAIL od(nolock)
	ON l.order_primary_reference = od.externorderkey
	and l.line_number = od.externlineno
LEFT JOIN wms_PICKDETAIL pd(nolock)
	ON od.orderkey = pd.orderkey
	and od.orderlinenumber = pd.orderlinenumber
	and pd.qty > 0	--if zero, we don't want a caseid
LEFT JOIN vw_Manifest m(nolock)
	ON o.primary_reference = m.order_primary_reference
	and pd.caseid = m.caseid
WHERE ft.trans_module = 'ORDERS'
	AND ft.trans_submodule IN ('SHIPPED','ERROR','CANCELED','SKIPPED') 
	AND ft.trans_submodule = o.order_status	
	AND ft.trans_status = '0'
	AND o.fulfillment_id = 840	--'IRD'
	AND o.customer_reference<>''
	AND o.order_type not in ('BACKORDER', 'PRODUCTION')	--9/17/2013
	--AND b.batch_reference = 'IRDXML'
	--AND o.release_date > '2013-05-20'	--filter out old orders before go-live
	AND o.add_date > CASE 
						WHEN @@SERVERNAME = 'AFSSQL01'
						THEN DATEADD(MONTH,  -6, GETDATE())
						ELSE DATEADD(MONTH, -36, GETDATE())
					 END
-- drop table #Temptbl


_________________________________________________________________________________________________________
/*							ATP-blank
							move all todds files from Robs account to his own
							1/22/19 - 

List of all programs Todd is using
Pageflex Persona						Bartender
Command Workstation/FIERY				Adobe Suite
Excel									RDP
Outlook									Fontlab Fontographer 5
Word									Skype
Access									ScreenConnect
OneNote									FileZilla
jetletter								foxpro

Per web page @ thewindowsclub.com admin can copy files from one user to another via
CTRL + C then CTRL + V 

admin account isnt working to accomplish this so going forward with filipes method
C: is local and can copy everything to a temp directory there
so go into C: create new folder TempXfer
starting to copy everything from Robs files into here
moving 76GB of data from Robs H: over to this C: now.
hopefully this works to help setup and config everything to Todd's account

most all of his programs are working but nav wont print properly
and pageflex wont load something

nav error is with afsweb204\content\navigator\templates\XMLprintdocuments\PGK\ -- any sykes xml in here
saying access to above path is denied. may be different error on robs comp. but todds may be permission

so in pageflex setup is showing temp output
C:\Users\TODD~1.LEW\AppData\Local\Temp\
final output : C:\Pageflex\Persona8\Programs\PersonaOutput
job log : C:\Pageflex\Persona8\Programs\PersonaLogFiles
SMTP server settings for email localhost

in generate output menu final output folder \\Masdp01\C751

MASDP is a user they use to print with through nav
printing still works for Robs acc just needed path fixed to find project files


think above may be configured correctly for Rob.
walk through how he logs in and goes to print again
have to find project file again
comes down to a user role or permission someone im guessing todd doesnt have

Robs xmltemplate docs 

___________________________________________________________________________________________
afsMFT02

can force shut down with cmd prompt shutdown /r /f
HpZUiEfIa0 sysadmin pw GQpWWtq8
21.102 
might not have correct gateway or services running
bad patch or antivirus 

TIP: The certificate may be changed later in IIS Manager or the MOVEit Transfer Config utility.

kbb user guide

144.217.57.63
troubleshooting FTP server issues.Called flexential they claim none of the issues are from
the FTP server but took a while to get the server up and running for MFT02. turns out it had
firewall turned on. Trying to learn set up for FTP server software MOVEit then called them for 
assistance on set up and getting right documentation to use to configure everything. finally 
figured out how to set up and restore from other server. this however caused issues. continued 
to validate and troubleshoot how to set up properly and had to uninstall and reinstall several 
times to get settings correct. but also to test fresh install vs restored. other server started working again so we determined 
we still dont know every root cause besides traffic. going to whitelist all clients

IP of mft02 is 192.168.21.102
mft01 is 192.168.21.105 i believe
aero dc and add host name to IP address for internal lookup using DNS

go to rdp and find mtf01 or mtf02 for new
here you can configure IP address to white or black list as well as on the fire wall
need to find the moveit transfer credentials in keepass for logging in to
add those white list /black list rules. 

in IE go to http://localhost/
use login sysadmin
and pw GQpWWtq8
on mft01 to access where we can whitelist IPs

						atp-14290 and atp-14379
adding client users to ftp 
log in to scftp.aerofulfillment.com as techadmin
go to users and add new.
need name and email and once created it will send link
for them to confirm and set password to log in
need to also make sure this user gets whitelisted

JustinnMcDaniel
ix8vsz


_________________________________________________________________________________________________________
/*							ATP-13982
							Aero SFTP server issues
							AERO
							1/25/19 - 1/


clear that project sticks with me
to provide cutover solutions for dns files and migration to new ftp server

steps for migration of sftp server
1 log in to flexential and view configs and set up
2 need to start exporting or transferring dns files without it interfering with live server
3 

orders id is what joins orders to line item edit

unable to sign into portal secure sign on
- d1yKDaS

NICs
About VMkernel NICs
vMotion—Enables the VMkernel adapter to advertise itself to another 
host as the network connection where vMotion traffic is sent. ...
Management Traffic—Enables the management traffic for the host and VMware vCenter server. ...
Fault Tolerance—Enables fault tolerance logging on the host.


_________________________________________________________________________________________________________
/*							ATP-13877
							FCSMPLPUSHPULL1819 backorders will not release due to incorrect UOM
							PEP 887 PPS 1096 LEB
							1/28/19 - 1/

supposedly almost 900 orders involved with the issue. orders come in as eaches and need to be as cases

need to see if we can change default_uom to case from eaches. will this be a simple update?
check skus on these orders

need to actually update uom on lineitem

--select *
from lebanon.dbo.inventory i(nolock)
join lebanon.dbo.Lineitem l (nolock) on l.item_id = l.item_id and l.fulfillment_id = i.fulfillment_id
join lebanon.dbo.orders o (nolock) on o.orders_id = l.orders_id
left outer join LEBANON.dbo.wms_orders wo (nolock) on wo.EXTERNORDERKEY = o.primary_reference
where i.fulfillment_id = 1096
and o.order_status = 'ACTIVE'
and i.primary_reference = 'FCSMPLPUSHPULL1819'
and l.line_status <> 'SHIPPED'
and l.item_id = 415078
order by o.add_date desc

-- BEFORE THIS UPDATE UNALLOCATE ALL ORDERS
-- can be done through infor via wave maint or manually by orders
-- then back all orders out after ficing / updating uom 
-- use reverse wave or reverse order proc

-- select *
from lebanon.dbo.Lineitem l (nolock) 
join lebanon.dbo.orders o (nolock) on o.orders_id = l.orders_id
where l.item_id = 415078
and l.uom = 'EA'

UPDATE l SET qty_ordered = l.qty_uom * pd.units, qty_open = l.qty_uom * pd.units, packkey = i.packkey, uom = i.default_uom
	FROM Lineitem l(nolock)
	INNER JOIN Inventory i(nolock)
		ON l.item_id = i.item_id
	INNER JOIN Inventory_PackDetail pd(nolock)
		ON i.packkey = pd.packkey
		AND i.default_uom = pd.uom
	WHERE l.order_primary_reference = @primary_reference
		AND l.qty_ordered <> (l.qty_uom * pd.units)
-- use this above update line combined with my update to get inv_packdetail and set line also gets def uom
-- should look like this
	
--UPDATE l SET qty_ordered = l.qty_uom * pd.units, qty_open = l.qty_uom * pd.units, packkey = i.packkey, uom = i.default_uom
-- select *
from lebanon.dbo.Lineitem l (nolock) 
join lebanon.dbo.orders o (nolock) on o.orders_id = l.orders_id
INNER JOIN Inventory i(nolock)
		ON l.item_id = i.item_id
	INNER JOIN Inventory_PackDetail pd(nolock)
		ON i.packkey = pd.packkey
		AND i.default_uom = pd.uom
where l.item_id = 415078
and l.uom = 'EA'

-- 
-- this now should show all orders from yesterday
--select *
from lebanon.dbo.inventory i(nolock)
join lebanon.dbo.Lineitem l (nolock) on l.item_id = l.item_id and l.fulfillment_id = i.fulfillment_id
join lebanon.dbo.orders o (nolock) on o.orders_id = l.orders_id
inner join LEBANON.dbo.wms_orders wo (nolock) on wo.EXTERNORDERKEY = o.primary_reference
where i.fulfillment_id = 1096
and o.order_status = 'ACTIVE'
and i.primary_reference = 'FCSMPLPUSHPULL1819'
and l.line_status <> 'SHIPPED'
and l.item_id = 415078
and wo.adddate < '2019-01-29 00:47:03.047'
order by o.add_date desc

_________________________________________________________________________________________
expense report jan 
1/3 full 26
1/11 full 26
1/17 full 26
1/23 half 13
1/24 full 26
1/25 half 13
1/30 half 13

total miles 143 * .555 = 79.37


_________________________________________________________________________________________________________
/*							ATP-12568 ATP-12789 CI-239 CI-203
							child meter set up for ZEVO, VARTA, ONNIT & COTY

							1/28/19 - 1/

so far added these for above Child meter tickets
in tms interface_test

			--1-29-19 added ZEVO fulfill - #BSY
		WHEN @SUSR2 LIKE '%UPS%' AND @storerkey='ZVO' AND O.susr2 = 'zevo'  THEN
			'AFS_ZEVO'

			--1-29-19 added COTY fulfill - #BSY
		WHEN @SUSR2 LIKE '%FXWS%' AND @storerkey='CTY' AND O.susr2 = 'coty'  THEN
			'AFS_COTY'

			--1-29-19 added ONNIT fulfill - #BSY
		WHEN @SUSR2 LIKE '%FXWS%' AND @storerkey='ONN' AND O.susr2 = 'onnit'  THEN
			'AFS_ONNIT'

			--1-29-19 added VARTA fulfill - #BSY
		WHEN @SUSR2 LIKE '%FXWS%' AND @storerkey='VAR' AND O.susr2 = 'varta'  THEN
			'AFS_VARTA'

havent done anything in devtms shipper config yet

issue in devtms 2/21 and 2/25 error when opening dmsmanager
error [481]invalid picture

according to google search go to computer then advanced then environment variables
locate TEMP variable in user variables. value listed is temp dir for current user
 optional work drive from within the FRx Designer, click on admin menu, and then click
processing options. optional work drive value is displayed on right side of screen that appears
may be dif. delete files to inc avail disk space on drives containing above dirs. 

issue with getting into vxcontroller
talked to josh, apparrently need to just manually start the service vxcontroller in services

able to update zevo's address in uat/devtms now need to test

issue with printing devtms labels to zebra in IT is the IP address used to talk to it was incorrect filipe and james figured out
and are now able to print to it.

VR0000000354
varta test order

make sure labels look good
/ are configured before printing and sending to fedex

after we confirm they look appropriate we can push to prod
B!ngCr0sby

_________________________________________________________________________________________________________
/*							ATP-14017
							ASN from pure are not in infor acknowledged on 1/8 at 10:56a and 4:55am
							control files are 51507 confirm recvd 
							and put in infor
							1/30/19 - 1/30/19

same as atp-13829

query scprd.wmwhse1(2).API_RESPONSE

where ? -- sourcekey NO


select *
from wmwhse1.API_RESPONSE (nolock)
where error like '%item%'
and MESSAGETYPE in ('ItemMasterAPI','PurchaseOrderAPI')
and RESPONSEDATE > '2019-01-27 06:00:05.680'

cross check times with boomi and file name etc.

check to see if item both boomi and logs found is in infor and nav
in this case item wasnt set up at all. 
older ticket above the items werent updated till after import
having ops setup sku then client will resend


_________________________________________________________________________________________________________
/*							ATP-14046
							Please ship complete LC784825 and LC784767 these have left the building
							1/31/19 - 1/31/19
doesnt look like an IT issue. these arent being held up in system by anything i can see.

guadalupe said there are no errors.. but using LTL manager to ship



_________________________________________________________________________________________________________
/*							ATP-14043
							Add to group. add erin jones to pep email group
							1/31/19 - 1/31/19

i tried to add but wont let me save update to group members because i dont have permission



_________________________________________________________________________________________________________
/*							ATP-14015
							Urgent: mason ops phone and printer not working
							1/30/19 - 1/30/19

doug unplugged phone which powers printers internet connection.

had to switch cat 5 cables and other stuff around. had to troubleshoot with another phone in
building

called Filipe for troubleshooting tips. said to check where cables are leading to
test phone on other phone.

eventually switched cables and inputs on phone and it finally turned on.
just a very old phone on its last limb and took forever to start

reference 113
port 6000 was reading 6001 and policy was set up incorrectly

policies within firewall
causing issue
may have been firewall policies from provident set up to be talking incorrectly to
afstms01

mas-inv01

getting drivers for printer and zebra and scale

use regedit to clear out info ship from registry if stuck on devtms01

this is path to tms edit between dev and afs
Computer\HKEY_CURRENT_USER\Software\VB and VBA Program Settings\DMSClient\Config

1772
1768
1774
1777
1770
1769
1779
1776
1773
1775
1778
1780



_________________________________________________________________________________________________________
/*							ATD-12
							Get quotes for projectors in following meeting rooms
							2/4/19 - 2/4/19

CDW for projector vending
quote out pricing

5 rooms total
Como
Atacama
Training
Exec
?

general - good wire management especially clean looking in exec rooms
	consistency across projector models so bulb replacement is easy and 
	requirement of 1080p and strong lumins
	ports only need VGA and HDMI

	get CDW's input on solid proj units to buy with those base qualifiers.
	quote out pricing for those units and installation

Como -
	wall opposite window is where itll be projected to. so above window
	we want the projector on a shelf. want white board paint for the whole wall
	being projected on. good wire management and wire mount for floor and table

exec -
	want to ceiling mount but unsure if drop or not drop ceiling. if drop we would have
	to do ourselves. if not drop we can contact people who ran wires/fibre for us?
	wire management has to look really nice since John will be there a lot.

training - 
	biggest room will require much longer HDMI cords. measure out to see
	where best placement for projector will be(depends on proj display distance).


talked to matt? on phone should get back to me with quote.
calling back today - 2/11 to try to get quote 
phone #  8776813261 email matlevi@cdw.com

Quote out projectors for meetings rooms and also wire management to wall or ceiling mount all devices.

3 - 5 new projectors - Epson
Many wires ran for wire management - each room has different lengths needed to reach from mounted projector to meeting desk
– Machu Pichu - 30ft ceiling proj to desk mount
– Zug - 28ft ceiling mount to desk mount
– Training room - 22ft wall to mount. 35ft projector to desk mount
– Positano - 6ft wall to desk mount / projector
– Exec? 
– Como - 15ft wall mount to desk mount


_________________________________________________________________________________________________________
/*							ATP-14049
							please make last print a required field in the version information section
							in item set up (add item/inventory) confirm will work on stock low rep
							2/4/19 - 2/4/19

nav
windows nav data form designer 
webinventory edit -- last print right column set required to true
check if this will report correctly on AWI low stock report? asking about this part

---------------------------
ON%32601 or
ON%32602 or
ON%30603 or
ON%30604 or
ON%30605 or
ON%30606

nothing holding these up, they shipped complete
listcontrolname from label to date

_________________________________________________________________________________________________________
/*							ATP-14042 and ATP-14068
							Intl orders not staging 
							2/4/19 - 2/5/19


select *
from mason.dbo.orders o (nolock)
left outer join mason.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
where o.primary_reference in ('OC0002137244', 'CP0001638723')

-- CP0001638723 stage correctly
-- OC0002137244 did not scan to stage says invalid shipper

-- still an issue OC0002138627 & OC0002137244 

if not on domain outside of network, need to be on whitelist to hit our ftp server

giant issue with CLS for PGOC this was in their test and not production

also any order going to a US territory needs to be PR PR for state and country or GU GU etc

cannot ship fedex to these countries need to do USPS non international

calls with chuck a few times helped solve this.
need to get with an exports specialist for more shipping details dealing with NOEII codes
bookmarked page for fedex

more notes below need to organize better

_________________________________________________________________________________________________________
/*							ATP-14081
							dx order batch alert
							2/5/19 - 2/5/19
archanas ticket just using for notes
The import process errored out because of connection issue. I deleted the batch and 
imported the order file

_________________________________________________________________________________________________________

-- making test manifest record in UAT
-- courtesy of Cory

-- atp-14558 #BSY 4/1/19
#manifest 15047 5/13/19
use lebanon

--order that you need to create a manifest record for
declare @orderNumber varchar(12) = 'RA0000015751' --must be at least allocated in Infor


INSERT INTO MANIFEST (
	   [trackingnumber]
      ,[caseid]
      ,[order_primary_reference]
      ,[void]
      ,[weight]
      ,[charge]
      ,[sur_charge]
      ,[packages]
      ,[bol]
      ,[carrier]
      ,[service]
      ,[thirdpty]
      ,[cod_package_flag]
      ,[consignee_residential_flag]
      ,[saturdaydelivery_flag]
      ,[oversize_flag]
      ,[bill_flag]
      ,[signature_flag]
      ,[aro_consignee_billing_flag]
      ,[aro_freight_collect_flag]
      ,[tran_date]
      ,[ship_date]
      ,[status]
      ,[add_date]
      ,[edit_date]
      ,[add_who]
      ,[edit_who]
      ,[billing_period]
      ,[billing_status])
SELECT distinct
'TestTracking1234' AS [trackingnumber]
      ,pd.caseid AS [caseid]
      ,wo.externorderkey AS [order_primary_reference]
      ,'N' as [void]
      ,convert(decimal,cd.[weight]) as [weight]
      ,0 as [charge]
      ,0 as [sur_charge]
      ,1 as [packages]
     ,'' as bol
      ,s.[service_name] AS [carrier]
      ,s.[description] AS [service]
      ,'N' as [thirdpty]
      ,'0' as [cod_package_flag]
      ,'1' as [consignee_residential_flag]
      ,'0' as [saturdaydelivery_flag]
      ,'0' as [oversize_flag]
      ,'0' as [bill_flag]
      ,'0' as [signature_flag]
      ,'0' as [aro_consignee_billing_flag]
      ,'0' as [aro_freight_collect_flag]
      ,getdate() as [tran_date]
      ,getdate() as [ship_date]
      ,0 as [status]
      ,getdate() as [add_date]
      ,getdate() as [edit_date]
      ,'Testing' as [add_who]
  ,	'Testing' as edit_who,
	'' as billing_period,
	0 as billing_status
from wms_orders wo
join wms_pickdetail pd on pd.orderkey = wo.orderkey
join scprd.wmwhse1.casedetail cd on cd.caseid = pd.caseid
join Ship_Method s on s.ship_method_id = wo.intermodalvehicle
left join vw_manifest m on m.order_primary_reference = wo.externorderkey and m.caseid = pd.caseid
where wo.externorderkey = @orderNumber
and m.manifestkey is null

-- intl order dig deeper in staging process
print empty blank label then go back and reprint after staging

-- notes from wade 
how did you do what you need to
communication biz to IT
think through whole bigger picture
not just code code code


_________________________________________________________________________________________________________
/*							ATP-14110
							Ket missing orders
							2/6/19 - 2/7/19

went through boomi process reporting and found all but 4 imported from excel sheet listing
all orders

josh pointed out that can search via documents on key field with numbers provided.
process reporting > documents -- instead of PR > executions


-- NOTES
-- ONN orders pdweb01


--- NOTES
-- allocation trace - for did not allocate or other lot errors
-- wms > execution > trace options > allocation trace - enter order id

-- https://aerofulfillment.atlassian.net/wiki/spaces/BD/pages/541130753/Process+stuck+in+Pending
-- james doc in conf for morning process to check on pending boomi jobs
-- stop sched for afsatom01 in boomi ALL JOBS then remote to afsatom01 and start menu search services
-- stop this service for afsatom then resume it. then resume scheduled boomi jobs

-- NOTES FOR CLS STAGING FOR INTL ORDERS - PGOC UPDATE
-- shipper not configged to do staging. designed around requirements from Aero.
-- intl shmt should be processed as single trans. need clear as single expense and expediancy
-- 5 sep custom clearance fees instead of 1 big one multi piece shipment
-- box scanned chk to see intl then write to holding table and set aside
-- temp label staged order indiv stored in tmp table
-- stored proc saying last order from stage
-- will require outage to make config change to add shipper to stage
-- server down cant process during this time or a break period. 


_________________________________________________________________________________________________________
/*							WEEK OF 2/11/19
							Notes and goals
							2/11/19 - 2/15/19
Continued -
Need to finish child meter testing. 
Have Dean contact Stites Scales - he will 2/12
Finish projector quotes, need to call them back because they havent called- left message hasnt resp 2/13
Get CLS to push update for 'AFS_PGOC' to info ship - need both WH on same page
Fix my aero nav aero10.sln - delete old repo and pull updated one (not ideal)
finish fixing printer driver on afsterm01 - finished

New -
estimated project for vayyar similar to KET scanners
 - need tablets and update network? 
project for new interface for freight man dashboard and etc.


_________________________________________________________________________________________________________
/*							ATP-14161
							Missing orders CPG PGOC
							2/11/19 - 2/21/19

missing orders.
went to boomi order import
checked dates given
see successful imports but with error emails going out.
customer didnt provide appropriate import data in some consign fields meaning likely
too short or nothing or too long
also majority of missing order errors were due to ship_address_1 data being required
meaning the address data they entered was in wrong field.

went all the way back to jan 21 to get orders to csv files to send to erin

first PGOC import looks like the map is ALL wrong
the below map function looks identical for shiptoname(consignee) and Shiptocompany

comp atten addy1
|		|	|
PGOC_GET_CONSIGNEE
|		|	|
SHIPTONAME


comp atten addy1
|		|	|
PGOC_GET_ATTENTION
|		|	|
SHIPTOCOMPANY

above would def cause the consignee length issue.
also only address3 is going to ship address1

created excels to help define issue with client and talked through with erin on 2/19
2/20 meeting with client and explaining issue but then working on resolution

documenting issues
-- mapping they sent didnt match ours even though we havent changed map since 2/13/2017

apparrently in oct they change send methods from email to ftp or something of this nature
probably root cause

however issue was we need street address in address 1 and 3 
because 3 was mapped to ship to addy
and 1 went to consign and company

most of this isnt needed for the concats for combining field data for consign and co
removing this and mapping 1 - 1 but there is a def value for consign as dental professional

they are resending all from oct orders and will hit system probably mid day 2/21

need to deploy changes to prod

to view these in map there is an export to excel but this doesnt look very clean
not sure how josh made changes other than just fixing up in excel
used import file example and 1 order that was successful
US_AERO2019... and pgoctest file nammes

so now mapping shows add1 to add1
aady 3 to addy 3
company to company
atten to atten with def value dental professional
removed extra concat logic functions

csv in excel removes leading 0's for columns B, O and P

more mapping issues worked on with josh h 2/21 until 7. need to sort orders differently 
and fix map. switch company and atten,

working again with importing these order 2/22 with simm shady
he did the file editing this time and then i helped him fix map
we got all working for importing correct data in fields

he has a list of errors that remain

backing out batch that had its orders consign and states/cities not matching
simm shady edited in excel improperly so these were out of place. 

remaining issues with addy 2 - erin will follow up with client - we dont know what 4 dig is
address 3 and company - too long of string lengths allowed 45 from their side 30 chars from us

2/25
afterwards erin said lots of orders made it to infor with nothing in nav. meaning 
that they ran and were on boomi job to go from nav to infor when i rolled them back out
by batch id.

so identified the orders using this sql and then pasted into infor

select *
from mason.dbo.orders o (nolock)
right join mason.dbo.wms_orders wo on wo.EXTERNORDERKEY = o.primary_reference
where o.primary_reference is null
and wo.STORERKEY = 'PGOC'

 and created a wave then
deleted the whole wave using this 
(had to find this through a trail from delete orders everywhere to delete batch
to deleteorderPRD1 to deleteorderswavedPRD1)

-- test
-- exec [dbo].[pr_DeleteOrdersWaved_PRD1]'0000334720'
_________________________________________________________________________________________________________
/*							ATP-14124
							IRD FTP
							2/7/19 - 2/8/19

filipe was notified from wanda of trouble connecting to ftp from IRD
we needed their IP to whitelist
filipe whitelisted on aero fw
i had BAE integration (via flexential portal) add/append to recently appended WL to firewall
policy from earlier last week.					



_________________________________________________________________________________________________________
/*							ATP-14171
							LW1533 stuck in part shipped status order has left. shelf life error
							2/12/19 - 2/12/19

update using -1 shelflife to wms_orderdetail


_________________________________________________________________________________________________________
/*							ATP-14175
							unlock MASQA2 acc dont change PW
							2/12/19 - 2/12/19

use mas-dc1 
active directory
search masqa
right click properties on masqa2 and go to account then check box unlock account
then click apply and then okay.


_________________________________________________________________________________________________________
/*							ATP-14173
							When trying to ship KB0000157475 infoship stating
							carton cannot ship because of PO box. no PO box on addy
							2/12/19 - 2/12/19

seems like this could be related to intl orders error on 14042
but the ticket doesnt give specific error. and once again theres a couple different
ship methods being used for orders going to this address over past year.

actual error from picture:
unable to ship: cannot enter FTR and Export License Number (2142)

chucks response:
"Nope, what you have is a data error.  I'm guessing you are passing both item_license_number 
and an sed_exemption_number in either the stored proc (infoship) or the XML (blackbox)."
above is only when trying to ship and country PR and state PR

different error maybe when ship for country US state PR

changing tms proc to add logic for if country us and state pr set country to PR to have
the proc change the sed to NOEEI 30.36 otherwise itll be blank
but somehow older orders went through to PR without that sed
nOEEI 30.37A or NOEEI30.37
exemptions for value of goods for SCHED B
aka under 2500

CA has different NOEEI

most shipments made to PR 
(No column name)	description	ship_region	ship_country
2135	USPS First-Class Mail	PR	US

HOWEVER via CLS chuck torrens non us-50 should ALWAYS go into system
as territory as country and territory as region

NLR no license required. 

item license number suppposed to be driven in tms item interface
-- nothing appears for any non aero ID or license

-- usps ship methods to try 19030 or 13023

-- josh helping me learn how to use count 


-- counts for country vs region being shipped 
select count(*),sm.description, o.ship_region, o.ship_country
from mason.dbo.orders o (nolock)
left outer join mason.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
left outer join mason.dbo.wms_ORDERDETAIL od (nolock) on od.EXTERNORDERKEY = o.primary_reference
left join mason.dbo.wms_PICKDETAIL p(nolock) on p.ORDERKEY = od.ORDERKEY and p.sku = od.SKU
inner join mason.dbo.Ship_Method sm (nolock) on sm.ship_method_id = o.ship_method_id
 where --o.primary_reference in ('KB0000157475 ','KB0000157480','KB0000125279','KB0000120481')
 (o.ship_country = 'PR'
--and o.parent_short_name = 'PGOC'
 OR o.ship_region = 'PR')
 and o.order_date > '2018-02-03 12:00:45.930'
group by sm.description, o.ship_region, o.ship_country
order by 1
--order by o.add_date desc


_________________________________________________________________________________________________________
/*							ATP-14136
							these users need access to pack key wizard 4528 4479 4449 4573
							2/12/19 - 2/12/19
use smartconnect portal to config

should look up who has access to PK wizard and copy that onto these users

enterprise then tables and ASP

select r.*
from enterprise.dbo.aspnetusers u(nolock)
join enterprise.dbo.AspNetUserRoles r (nolock) on r.UserId = u.id
where u.email like '%hodge%'
and u.Id = '6b1c853e-e4a7-45fb-852c-aaa15e99d848'

select *
from ENTERPRISE.dbo.AspNetRoles (nolock)
where Id = '088BAA6C-C02A-4B88-8C29-206BFC89941C'

insert into enterprise.dbo.aspnetuserroles
select
	[UserId],
	'088BAA6C-C02A-4B88-8C29-206BFC89941C' as RoleId,
	[Discriminator]
from ENTERPRISE.dbo.AspNetUserRoles
where UserId = 'c2c128ae-24aa-4e33-901a-692132384898'

____________________________________________________________________________________________________
notes for cpg estore pgp testing in UAT web navfor james
-- would not let upload of image occur.
-- image upload succeeded while testing importing catalog
-- successful catalog import however looks like it deleted or removed 2 existing catalogs

-- james thinks issue couldve been because those catalogs were created on his local machine
-- image uploads all work
-- also the catalog import is supposed to remove old catalogs


____________________________________________________________________________________________________

stevesales@fuse.NEt
18007557875 tech support with avery
flat rate to check no service contract 90 day cert avail online

plan to talk to field manager to have someone come out next week to help configure

have them teach us so we can set up on our own. need service manual only they have

need to use ethernet because USB needs a usb module installed on scale for computer interfacing

192.168.4.192



_________________________________________________________________________________________________________
/*							ATP-14202
							CP0001638604 showed shipped in nav web but no manifest or tracking
							was shipped 2nd time. how did it not work first time?
							2/14/19 - 2/14/19

fulfill tran on ordersid
shows shipped 2/06
then shipmethod changed on 2/14
checking on other queries

initially shipped complete on 2/6 by user 6031
probable cause
Joe Wicks

_________________________________________________________________________________________________________
/*							ATP-14194
							Ivonne cant see drop down in nav for clients

							2/14/19 - 2/14/19

looks like it can configged by changing her roleid. want to see whom she should mirror


_________________________________________________________________________________________________________
/*							ATP-14176
							AFI orders stuck
							2/13/19 - 2/14/19

orders dont look stuck but going to check out how inventory report 731 - test is working
 and giving possibly inccorrect data

_________________________________________________________________________________________________________
/*							ATP-14191
							RAS/AOS over-allocation off replen report
							2/14/19 - 2/14/19
(Allocation Issues with Bulk v2)

he thinks its mainly replenishing to forward pick

proc looks like it uses both forward and bulk but not sure on its logic on which to
replen to

want it to assume items will be allocated as pallets or cases to bulk


_________________________________________________________________________________________________________
/*							ATP-14183
							reception desk computer of gloria's only letting 2 time sheets be 
							entered at a time. got an error
							2/14/19 - 2/14/19

what is the error message? does this happen for just rose or also for gloria?


_________________________________________________________________________________________________________
/*							ATP-13903
							add description to error orders
							vayyar
							2/18/19 - 2/26/19

either A rewrite to mimic lydia PGOC cleanse shape usage 
or B fix what exists that may not look good

-- first confirming with Kim what the error email even looks like
because i cannot find what the source it. doesnt seem to be coming from 
any vay boomi job.

-- per josh have to find on my own. 

select * from Fulfillment_Events
where fulfillment_id = 1162
OrderError.rpt 
look up vayyar info for error order notifications in this report

in report in crystal see path Event_OrderStatusChanged

look up this event in leb views
and its source is OrdersSearch joined with Fulfillment_Transaction

after doing a select top 1000 and filtering on ffid 1162 and add date 
found that all the vay errors are populated in approval reason
mostly duplicate ref
so mapping this to the report and putting into production

query below shows this filename for 1/15/19 - trying to figure out where when how
this applies to anything

select *
from lebanon.dbo.Fulfillment_Event_Log
where fulfillment_id = 1162
and add_date > '2019-01-06 09:20:42.577'
and event_id = 7
order by add_date desc

\\afsweb204\content\Navigator\export\20190115\eafa6187-b927-4bfa-b31d-f0f053cd7dca.pdf

test by adding a sub going to me



0000736099

_________________________________________________________________________________________________

-- varta and zevo license
-- 3 conf room phones
-- Jason Stidham
-- Sr. Account Manager
-- Office/513-397-4759
-- Cell 513-236-7048

for fedex web services
create new meter in vx by clicking new or create
use appropriate info from license and etc for address info
click fedex web
click commission
this will populate credentials
doesnt need bill info
now we can ship out on web service ship methods to validate billing info with fedex

ups smart/surepost same process
except after commision need to physically ship
and once something is shipped need to populate fields in here
to verify billing info with invoice amount invoice number etc

after either of these are done need to make sure we have cx
assigned to client bill client for cost of setting up meter

_________________________________________________________________________________________________


-- switching buildings - or other side of wall causes user ids to not work
-- could be some users or rf on mason and other side only covered by secure
-- or more likely they are all set up as aero mason which for some reason doesnt
-- read as mason on other side of wall

-- testing for ship station orders for documents
-- create orders using 99999 as item and make diff orders for diff ship methods
-- you will have to go into Infor and create a wave for 
-- this order, release the wave, and pick the order.
-- PL0000026079  CP0001644007 KB0000158310
-- 
-- remove extra docs from documents in info ship
-- hit f3 once entering case id then rate then f12

cpg estore test with james

scenario
-- use data given to register from login page
-- make sure to use registration code at top 
-- fill in random address and email data
-- make sure to write down or copy email addy and PW - will be used to log in on next step
-- log in
-- have them find the mr clean product and so forth
-- the default text in search box is misleading cannot search from master catalog level
-- after selecting the qty cannot hit enter to force add to cart
-- look through catalog for mr clean prf disinfesting multi purpose cleaner
-- select 2 for this item 
-- find a foaming hand soap dispenser and select 2 here as well white auto foaming
-- go to cart
-- confirm and explain discount then checkout
-- checkout and some screens effecting weird resolution issue
-- in check out try to use PO to pay and ensure pop up occurs
-- talk through the final checkout page
-- say how james is manually executing x y z and then we will view in quickbooks
-- here we see your aero order number at the top of the page
-- bug of splitting order items to 2 diff invoices
-- talk about james manually sending order to infor
then having him shipping said order in infor
after this he manually creates the invoice in quickbooks and be able to
display the invoice to them. then conclude test.
-- order RE0000002106

removed label for master catalog and next deploy that wont be displayed


_________________________________________________________________________________________________________
/*							ATP-14248
							rf guns kicking users off
							mason
							2/21/19 - 2/

-- issue with RF in mason for new ticket

-- tested with aeromason wifi and aerorf wifi
-- picker in bulk couldnt scan or perform and moves with aeromason
-- he says this is a common issue he saw both in FF and mason

-- however need to test further to see if regular pickers in mason have this issue
-- not in bulk picks


_________________________________________________________________________________________________________
/*							ATP-14257
							ship stations not printing anything on label that comes out
							mason
							2/21/19 - 2/22/19

called chuck at cls with start meeting

we discussed this as a possible application issue, however going through the symptoms
of:
scans caseid and it looks like it processes automatically as usual
however when printing the label nothing appears on the label
happening at all but one ship station
from supervisor
they changed all the stock rolls last night and now we are seeing this issue on all but one
chuck from cls says this could be one of few issues and wanted to test the stock
used fingernail to try and make a black line on it
was hard to do but with key it could scratch hard enough to do so. 
however when testing stock from the working machine it was possibly to draw
the black line with fingernail with ease and it was noticeable how different the 2 stocks felt
so we changed the stock in effected machines and they all started working

kicker is the box that had bad stock was identical to all other boxes
same sku and everything
so it mustve been the supplier or mfg who sent wrong product in this box


_________________________________________________________________________________________________________
/*						ATD-15
							order conf phones for leb/FF
							lebanon/FF/WC
							2/20/19 - 2/
aero leb cin bell account number
6583074

contacted Scott Sullivan at cinbel 

reaching out to learn more about licensing while also trying to get 3 conf phones for different
meeting rooms

2/22 email from scott containing info about new phones

aero leb cin bell account number
6583074

still need more details on licensing as we have extra licenses needing cleaned up

trying to see if we can reuse licenses from jean sharon and don 2/26

_________________________________________________________________________________________________________

														week of 2/25/19-3/1/19
finish from last week:
add desc to order error 13903 - done 2/25
Zevo Varta and Coty label tests in devtms - dmsman not working
CPG estore project
CONf phones and proj quotes - recvd both 2/26 revised
Finish documentations - ship stat, phone license? estore, AFI/AWI EOM

goals this week:
tackle new responsibilities if available
clear ticket queues - my existing and awaiting triage
help others
fix my github and figure things out in aero10.sln and sc.Sln
estore presentation

654740631 vart subaccount #
get afs_varta set up

_________________________________________________________________________________________________________
/*									ATP-14246
										roger cottle nav access
										2/26/19 - 2/26/19

needs pw reset for navigator

fixed in nav he has 2 accs just needs to learn how to login

_________________________________________________________________________________________________________
/*									ATP-14230
										RF scanner java error
										2/26/19 - 



_________________________________________________________________________________________________________
/*									ATP-14281
										order in part shipped status dude to shelf life RA45136
										2/26/19 - 

archana fixed

_________________________________________________________________________________________________________
/*									ATP-14230
										Zevo labels do not scan with RF gun
										2/26/19 - 

_________________________________________________________________________________________________________
/*							ESTORE atp-14307 &
								CPG
								2/26/19 - 

CPG e store test
login BenYAero
pw reg
have to get all the images myself?
josh going to reach out to tony

2/28/19 meeting downtown for estore
notes in excel from chris and changes quoted with james and josh
i will be assigned this next week

estore path for CSS
\\UATWEB02\Websites\UAT\eFulfillment\images\CPGR

webordersviewdetail has table needed fixed or appropriate cell sizing

order flow
1 catalog
2 pre checkout page = webshoppingcart - may be incorrect
3 checkout page = webshiptoaddress
4 this page has several data forms
-- order info = webordersviewinformation
-- shipping address = webordersviewshippingaddress
-- shipping info = webordersshippinginfo
-- payment addy and info = NAV CODE
-- order detail = webordersviewdetail
-- cost totals = webordersviewordertotal
5 ship confirm and place order = webshiptoorderinfo
6 order confirm = 

going to try to copy JS in nav code of ctrl_PaymentAndAddressInfo
into data form and try to replicate the billing address same as shipping

JS function to copy:
Private Function CreateAddressClientScript() As String
        Dim sb As New System.Text.StringBuilder
        With sb
            .Append("<script language=""javascript"">function setAddress(c){")
            .Append("if(c==true){document.getElementById('")
            .Append(Me.txtBillToAddress1.ClientID)
            .Append("').value='")
            .Append(Server.HtmlEncode(m_CurrentOrder.Header.Rows(0).Item("ship_Address_1").ToString))
            .Append("';")
            .Append("document.getElementById('")
            .Append(Me.txtBillToAddress2.ClientID)
            .Append("').value='")
            .Append(Server.HtmlEncode(m_CurrentOrder.Header.Rows(0).Item("ship_Address_2").ToString))
            .Append("';")
         -- remove bill and ship 3s  .Append("document.getElementById('")
         --   .Append(Me.txtBillToAddress3.ClientID)
         --   .Append("').value='")
         --   .Append(Server.HtmlEncode(m_CurrentOrder.Header.Rows(0).Item("ship_Address_3").ToString))
         --   .Append("';")
          -- remove   .Append("document.getElementById('")
          -- remove   .Append(Me.txtBillToAttention.ClientID)
         -- remove    .Append("').value='")
          -- remove   .Append(Server.HtmlEncode(m_CurrentOrder.Header.Rows(0).Item("ship_Attention").ToString))
           -- remove  .Append("';")
            .Append("document.getElementById('")
            .Append(Me.txtBillToCity.ClientID)
            .Append("').value='")
            .Append(Server.HtmlEncode(m_CurrentOrder.Header.Rows(0).Item("ship_City").ToString))
            .Append("';")
            .Append("document.getElementById('")
            .Append(Me.txtBillToZip.ClientID)
            .Append("').value='")
            .Append(Server.HtmlEncode(m_CurrentOrder.Header.Rows(0).Item("ship_postal_code").ToString))
            .Append("';")
            .Append("document.getElementById('")
            .Append(Me.txtConsign.ClientID)
            .Append("').value='")
            .Append(Server.HtmlEncode(m_CurrentOrder.Header.Rows(0).Item("consign").ToString))
            .Append("';")
            .Append("document.getElementById('")
            .Append(Me.txtEmail.ClientID)
            .Append("').value='")
            .Append(Server.HtmlEncode(m_CurrentOrder.Header.Rows(0).Item("email").ToString))
            .Append("';")

            'Select Boxes
            Dim ctyindex As Integer = Me.drpBillToCountry.Items.IndexOf(Me.drpBillToCountry.Items.FindByValue(m_CurrentOrder.Header.Rows(0).Item("ship_country").ToString))
            Dim stateIndex As Integer = Me.drpBillToState.Items.IndexOf(Me.drpBillToState.Items.FindByValue(m_CurrentOrder.Header.Rows(0).Item("ship_region").ToString))

            .Append("document.getElementById('")
            .Append(Me.drpBillToCountry.ClientID)
            .Append("').selectedIndex='")
            .Append(ctyindex.ToString)
            .Append("';")
            .Append("document.getElementById('")
            .Append(Me.drpBillToState.ClientID)
            .Append("').selectedIndex='")
            .Append(stateIndex.ToString)
            .Append("';")

            .Append("document.getElementById('")
            .Append(Me.txtPhone.ClientID)
            .Append("').value='")
            .Append(Server.HtmlEncode(m_CurrentOrder.Header.Rows(0).Item("phone").ToString))
            .Append("';}}</script>")
        End With
        Return sb.ToString
    End Function

also trying to fix visual studio issue once again where the .net framework it tries to target
is 4.6 instead of 4.7 which is the only one i have left installed.

josh helped me use revo uninstaller to find 4.6 an 4.5 .NET files and remove them

now running repair on visual studio

may need to also delete aero10 repo from files and re clone to my PC

-- css notes
-- trying to get correct id or class for the shipping verification w/ billing page

<table id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_tblPayment"
 class="PaymentDisplay" cellspacing="5" cellpadding="0" width="100%">
			<tbody><tr>
				<td id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_chkAddressCell"
				 width="35%" colspan="2">
                          <input id="chkAddress" onclick="setAddress(this.checked)" 
														class="list_txt" type="checkbox">
                          <span class="label_txt">Same as Shipping</span>
                          </td>
				<td align="right" width="50%" colspan="2">
                  <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblReqFields"
									 class="txt" style="color:Red;">* All fields in <b>
														RED </b> are mandatory</span>
                </td>
			</tr>
			<tr>
				<td>
                            <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblConsign" 
														class="label_txt" style="color:Red;font-weight:bold;">Name</span>
                              </td>
				<td>
                            <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtConsign"
														 type="text" value="Jack Sparrow" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtConsign" 
														 tabindex="1" class="list_txt" onkeypress="return EnterTabKeyPress(event)" style="width:150px;">
                        		</td>
				<td>
                            <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblPaymentMethod"
														 class="label_txt" style="color:Red;font-weight:bold;">Payment Method</span>
                          	</td>
				<td>
                            <select name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:drpPayment"
														 id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_drpPayment"
														  tabindex="11" class="list_txt" onchange="ChangePaymentType2(this);" style="width:154px;">
					<option selected="selected" value="">SELECT A PAYMENT</option>
					<option value="1">Visa</option>
					<option value="2">MasterCard</option>
					<option value="3">American Express</option>
					<option value="4">Purchase Order</option>

				</select>
                        </td>
			</tr>
			<tr>
				<td>
                 <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBillAttention"
										 class="label_txt">Attention</span>
                    </td>
				<td>
                    <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtBillToAttention" 
										type="text" value="Jack Sparrow" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtBillToAttention"
									 tabindex="1" class="list_txt" onkeypress="return EnterTabKeyPress(event)" style="width:150px;">
                    </td>
				<td>
                       <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBillAccount" class="label_txt"
											 style="color:Red;font-weight:bold;display:none;">Account Number</span>
                       <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBankAcctNo" class="label_txt"
											 style="color:Red;font-weight:bold;display:none;">Bank Acct No.</span>
                      <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblAccountName" class="label_txt" 
											style="color:Red;font-weight:bold;display:none;">Account</span>
                       </td>
				<td>
                         <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtBillAcct" type="text"
												 id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtBillAcct" tabindex="12" class="list_txt" 
												 onkeyup="keyUP(this);" style="width:150px;display:none;">
                         <br>
                       <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_warning" class="label_txt"></span>
                       <input type="hidden" name="POmask" id="POmask" value="ABC12345">
                       <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtBankAcctNo" type="text" 
												id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtBankAcctNo" tabindex="12" class="list_txt" style="width:150px;display:none;">
                        <select name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:drpAccount" 
												id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_drpAccount" tabindex="11" class="list_txt"
												 onchange="getAcctBalance(this.value);" style="width:154px;display:none;">
					<option value="">SELECT A PROGRAM</option>

				</select>
                                                </td>
			</tr>
			<tr>
				<td style="height: 35px">
          <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBillAddress1" class="label_txt"
					 style="color:Red;font-weight:bold;">Address 1</span>
               </td>
				<td style="height: 35px">
           <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtBillToAddress1" 
					 type="text" value="123 aero rd" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtBillToAddress1" tabindex="2"
					  class="list_txt" onkeypress="return EnterTabKeyPress(event)" style="width:150px;">
             </td>
				<td>
           <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBillAccountExpire" 
					 class="label_txt" style="color:Red;font-weight:bold;display:none;"> Expiration Date</span>
          <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblDriveLicState" class="label_txt" 
					style="color:Red;font-weight:bold;display:none;">Drivers Licence State</span>
          <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblAccountCreditLimit" class="label_txt" style="display:none;">Allotment</span>
          </td>
				<td id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_tdAcctExpire">
             <select name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:drpExpMonth" 
						 id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_drpExpMonth" tabindex="13" class="list_txt" style="width:45px;display:none;">
					<option value=""></option>
					<option value="01">1</option>
					<option value="02">2</option>
					<option value="03">3</option>
					<option value="04">4</option>
					<option value="05">5</option>
					<option value="06">6</option>
					<option value="07">7</option>
					<option value="08">8</option>
					<option value="09">9</option>
					<option value="10">10</option>
					<option value="11">11</option>
					<option value="12">12</option>

				</select>
           <select name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:drpExpYear" 
					 id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_drpExpYear" tabindex="14" class="list_txt" style="width:76px;display:none;">
					<option value=""></option>
					<option value="2019">2019</option>
					<option value="2020">2020</option>
					<option value="2021">2021</option>
					<option value="2022">2022</option>
					<option value="2023">2023</option>
					<option value="2024">2024</option>
					<option value="2025">2025</option>
					<option value="2026">2026</option>
					<option value="2027">2027</option>
					<option value="2028">2028</option>
					<option value="2029">2029</option>

				</select>
              <select name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:drpDriveLicState"
							 id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_drpDriveLicState" tabindex="13" class="list_txt" style="width:154px;display:none;">
					<option value=" "> </option>
					<option value="AL">ALABAMA</option>
					<option value="AK">ALASKA</option>
					<option value="AS">AMERICAN SAMOA</option>
					<option value="AZ">ARIZONA</option>
					<option value="AR">ARKANSAS</option>
					<option value="CA">CALIFORNIA</option>
					<option value="CO">COLORADO</option>
					<option value="CT">CONNECTICUT</option>
					<option value="DE">DELAWARE</option>
					<option value="DC">DISTRICT OF COLUMBIA</option>
					<option value="FL">FLORIDA</option>
					<option value="GA">GEORGIA</option>
					<option value="GU">GUAM</option>
					<option value="HI">HAWAII</option>
					<option value="ID">IDAHO</option>
					<option value="IL">ILLINOIS</option>
					<option value="IN">INDIANA</option>
					<option value="IA">IOWA</option>
					<option value="KS">KANSAS</option>
					<option value="KY">KENTUCKY</option>
					<option value="LA">LOUISIANA</option>
					<option value="ME">MAINE</option>
					<option value="MD">MARYLAND</option>
					<option value="MA">MASSACHUSETTS</option>
					<option value="MI">MICHIGAN</option>
					<option value="MN">MINNESOTA</option>
					<option value="MS">MISSISSIPPI</option>
					<option value="MO">MISSOURI</option>
					<option value="MT">MONTANA</option>
					<option value="NE">NEBRASKA</option>
					<option value="NV">NEVADA</option>
					<option value="NH">NEW HAMPSHIRE</option>
					<option value="NJ">NEW JERSEY</option>
					<option value="NM">NEW MEXICO</option>
					<option value="NY">NEW YORK</option>
					<option value="NC">NORTH CAROLINA</option>
					<option value="ND">NORTH DAKOTA</option>
					<option value="OH">OHIO</option>
					<option value="OK">OKLAHOMA</option>
					<option value="OR">OREGON</option>
					<option value="PA">PENNSYLVANIA</option>
					<option value="PR">PUERTO RICO</option>
					<option value="RI">RHODE ISLAND</option>
					<option value="SC">SOUTH CAROLINA</option>
					<option value="SD">SOUTH DAKOTA</option>
					<option value="TN">TENNESSEE</option>
					<option value="TX">TEXAS</option>
					<option value="UT">UTAH</option>
					<option value="VT">VERMONT</option>
					<option value="VI">VIRGIN ISLANDS</option>
					<option value="VA">VIRGINIA</option>
					<option value="WA">WASHINGTON</option>
					<option value="WV">WEST VIRGINIA</option>
					<option value="WI">WISCONSIN</option>
					<option value="WY">WYOMING</option>
					<option value="AB">ALBERTA</option>
					<option value="BC">BRITISH COLUMBIA</option>
					<option value="MB">MANITOBA</option>
					<option value="NB">NEW BRUNSWICK</option>
					<option value="NF">NEWFOUNDLAND</option>
					<option value="NS">NOVA SCOTIA</option>
					<option value="NT">NORTHWEST TERRITORIES</option>
					<option value="ON">ONTARIO</option>
					<option value="PE">PRINCE EDWARD ISLAND</option>
					<option value="QC">QUEBEC</option>
					<option value="SK">SASKATCHEWAN</option>
					<option value="YT">YUKON TERRITORY</option>
					<option value="NSW">NEW SOUTH WALES</option>
					<option value="NU">NUNAVUT</option>
					<option value="AA">AA</option>
					<option value="AE">AE</option>
					<option value="AP">AP</option>

				</select>
                                                    <span id="lblAccountCreditLimitAMT" class="list_txt" style="display:none;"></span>
                                                </td>
			</tr>
			<tr>
				<td style="height: 34px">
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBillAddress2" class="label_txt">Address 2</span>
                                                </td>
				<td style="height: 34px">
                                                    <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtBillToAddress2" type="text" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtBillToAddress2" tabindex="3" class="list_txt" onkeypress="return EnterTabKeyPress(event)" style="width:150px;">
                                                </td>
				<td style="height: 34px" valign="top">
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBillCV" class="label_txt" style="height:2px;width:120px;display:none;">CV Number</span>
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBankAcctType" class="label_txt" style="color:Red;font-weight:bold;display:none;">Bank Acct Type</span>
                                                    <br>
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblcvtext" style="color:Red;font-size:X-Small;font-weight:bold;font-style:italic;height:2px;width:120px;display:none;">*last 3 numbers on back of card</span>
                                                    <span id="lblAccountBalance" class="label_txt" style="display:none;">Available</span>
                                                </td>
				<td style="height: 34px">
                                                    <p>
                                                        <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtBillCV" type="text" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtBillCV" tabindex="15" class="list_txt" onkeypress="return NumberBoxKeyPress(event,0,46,false)" style="width:150px;display:none;">
                                                        <select name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:drpBankAcctType" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_drpBankAcctType" tabindex="15" class="list_txt" style="width:154px;display:none;">
					<option value="C">Checking</option>
					<option value="X">Corporate</option>
					<option value="S">Savings</option>

				</select>
                                                        <span id="lblAccountBalanceAMT" class="list_txt" style="display:none;"></span>
                                                        <br>
                                                    </p>
                                                </td>
			</tr>
			<tr>
				<td>
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBillToAddress3" class="label_txt"> Address 3</span>
                                                </td>
				<td>
                                                    <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtBillToAddress3" type="text" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtBillToAddress3" tabindex="4" class="list_txt" onkeypress="return EnterTabKeyPress(event)" style="width:150px;">
                                                </td>
				<td>
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblRoutingNo" class="label_txt" style="color:Red;font-weight:bold;display:none;">Routing No.</span>
                                                </td>
				<td>
                                                    <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtRoutingNo" type="text" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtRoutingNo" tabindex="16" class="list_txt" style="width:150px;display:none;">
                                                </td>
			</tr>
			<tr>
				<td valign="top">
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBillCity" class="label_txt" style="color:Red;font-weight:bold;">City</span>
                                                </td>
				<td valign="top">
                                                    <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtBillToCity" type="text" value="cincinnati" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtBillToCity" tabindex="5" class="list_txt" onkeypress="return EnterTabKeyPress(event)" style="width:150px;">
                                                </td>
				<td>
                                                    &nbsp;
                                                </td>
				<td>
                                                    &nbsp;
                                                </td>
			</tr>
			<tr>
				<td>
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBillToState" class="label_txt">State</span>
                                                </td>
				<td>
                                                    <select name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:drpBillToState" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_drpBillToState" tabindex="6" class="list_txt" style="width:154px;">
					<option value="">SELECT A VALUE</option>
					<option value=" "> </option>
					<option value="AL">ALABAMA</option>
					<option value="AK">ALASKA</option>
					<option value="AS">AMERICAN SAMOA</option>
					<option value="AZ">ARIZONA</option>
					<option value="AR">ARKANSAS</option>
					<option value="CA">CALIFORNIA</option>
					<option value="CO">COLORADO</option>
					<option value="CT">CONNECTICUT</option>
					<option value="DE">DELAWARE</option>
					<option value="DC">DISTRICT OF COLUMBIA</option>
					<option value="FL">FLORIDA</option>
					<option value="GA">GEORGIA</option>
					<option value="GU">GUAM</option>
					<option value="HI">HAWAII</option>
					<option value="ID">IDAHO</option>
					<option value="IL">ILLINOIS</option>
					<option value="IN">INDIANA</option>
					<option value="IA">IOWA</option>
					<option value="KS">KANSAS</option>
					<option value="KY">KENTUCKY</option>
					<option value="LA">LOUISIANA</option>
					<option value="ME">MAINE</option>
					<option value="MD">MARYLAND</option>
					<option value="MA">MASSACHUSETTS</option>
					<option value="MI">MICHIGAN</option>
					<option value="MN">MINNESOTA</option>
					<option value="MS">MISSISSIPPI</option>
					<option value="MO">MISSOURI</option>
					<option value="MT">MONTANA</option>
					<option value="NE">NEBRASKA</option>
					<option value="NV">NEVADA</option>
					<option value="NH">NEW HAMPSHIRE</option>
					<option value="NJ">NEW JERSEY</option>
					<option value="NM">NEW MEXICO</option>
					<option value="NY">NEW YORK</option>
					<option value="NC">NORTH CAROLINA</option>
					<option value="ND">NORTH DAKOTA</option>
					<option selected="selected" value="OH">OHIO</option>
					<option value="OK">OKLAHOMA</option>
					<option value="OR">OREGON</option>
					<option value="PA">PENNSYLVANIA</option>
					<option value="PR">PUERTO RICO</option>
					<option value="RI">RHODE ISLAND</option>
					<option value="SC">SOUTH CAROLINA</option>
					<option value="SD">SOUTH DAKOTA</option>
					<option value="TN">TENNESSEE</option>
					<option value="TX">TEXAS</option>
					<option value="UT">UTAH</option>
					<option value="VT">VERMONT</option>
					<option value="VI">VIRGIN ISLANDS</option>
					<option value="VA">VIRGINIA</option>
					<option value="WA">WASHINGTON</option>
					<option value="WV">WEST VIRGINIA</option>
					<option value="WI">WISCONSIN</option>
					<option value="WY">WYOMING</option>
					<option value="AB">ALBERTA</option>
					<option value="BC">BRITISH COLUMBIA</option>
					<option value="MB">MANITOBA</option>
					<option value="NB">NEW BRUNSWICK</option>
					<option value="NF">NEWFOUNDLAND</option>
					<option value="NS">NOVA SCOTIA</option>
					<option value="NT">NORTHWEST TERRITORIES</option>
					<option value="ON">ONTARIO</option>
					<option value="PE">PRINCE EDWARD ISLAND</option>
					<option value="QC">QUEBEC</option>
					<option value="SK">SASKATCHEWAN</option>
					<option value="YT">YUKON TERRITORY</option>
					<option value="NSW">NEW SOUTH WALES</option>
					<option value="NU">NUNAVUT</option>
					<option value="AA">AA</option>
					<option value="AE">AE</option>
					<option value="AP">AP</option>

				</select>
                                                </td>
				<td>
                                                    &nbsp;
                                                </td>
				<td>
                                                    &nbsp;
                                                </td>
			</tr>
			<tr>
				<td>
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblBillToZip" class="label_txt" style="color:Red;font-weight:bold;">Zip</span>
                                                </td>
				<td>
                                                    <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtBillToZip" type="text" value="45238" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtBillToZip" tabindex="7" class="list_txt" onkeypress="return EnterTabKeyPress(event)" style="width:69px;">
                                                </td>
				<td>
                                                    &nbsp;
                                                </td>
				<td>
                                                    &nbsp;
                                                </td>
			</tr>
			<tr>
				<td>
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblCountry" class="label_txt" style="color:Red;font-weight:bold;">Country</span>
                                                </td>
				<td>
                                                    <select name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:drpBillToCountry" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_drpBillToCountry" tabindex="8" class="list_txt" style="width:147px;">
					<option selected="selected" value="US">UNITED STATES</option>

				</select>
                                                </td>
				<td>
                                                    &nbsp;
                                                </td>
				<td>
                                                    &nbsp;
                                                </td>
			</tr>
			<tr>
				<td>
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblEmail" class="label_txt" style="color:Red;font-weight:bold;">Email</span>
                                                </td>
				<td>
                                                    <span class="txt">
                                                        <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtEmail" type="text" value="jsparrow@gmail.com" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtEmail" tabindex="9" class="list_txt" onkeypress="return EnterTabKeyPress(event)" style="width:150px;"></span>
                                                </td>
				<td>
                                                    &nbsp;
                                                </td>
				<td>
                                                    &nbsp;
                                                </td>
			</tr>
			<tr>
				<td>
                                                    <span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblPhone" class="label_txt" style="color:Red;font-weight:bold;">Phone</span>
                                                </td>
				<td>
                                                    <span class="txt">
                                                        <input name="_ctl0:MainContent:_ctl0:_ctl1:_ctl0:Ctrl_OrderDetail1:ctrl_PaymentAndAddressInfo1:txtPhone" type="text" value="5133331111" id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_txtPhone" tabindex="10" class="list_txt" onkeypress="return EnterTabKeyPress(event)" style="width:150px;"></span>
                                                </td>
				<td>
                                                </td>
				<td>
                                                </td>
			</tr>
		</tbody></table>

removed original price in ordersviewdetail DF because we mentioned cust shouldn’t see this


-- found in html - html doesnt need deployment - ctrl_PaymentAndAddressInfo.ascx html
<td align="right" width="50%" colspan="2">
      <asp:Label ID="lblReqFields" runat="server" EnableViewState="False" CssClass="txt">* Required fields</asp:Label>
            </td>
changed above to '* Reguired fields' instead of '* fields marked RED are mandatory'
however this doesnt change all the colors of the html label names in same html
 inherits from same file?
 code behind is ctrl_PaymentAndAddressInfo.ascx.vb
 probably where color is set

<span id="_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblConsign" 
class="label_txt" style="color:Red;font-weight:bold;">Name</span>

found how to change color below for bill info so adding above asterisk back for req fields

notes on using ::after in css. doesnt actually need to be added to html.
just add after class or id label like below:
first part changed the name to not be red
span#_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblConsign.label_txt {
	color: Black !important;
}
2nd part actually uses css to add text or 'content' after whats in the div as text/content
span#_ctl0_MainContent__ctl0__ctl1__ctl0_Ctrl_OrderDetail1_ctrl_PaymentAndAddressInfo1_lblConsign.label_txt::after {
	content: '*' !important;
}

html/ascx path 
efulfill\DesktopModules\
html file ctrl_CatalogItemsv2.ascx 
-- has catalog page with go to cart link that needs changed

-- 3/8/19 james doesnt believe i can change the value/price of catalog items i found above to display with $ instead of decimals in the html ascx file
suggests using sql convert() on view Inventory_New_Catalogs

_ctl0_MainContent__ctl0__ctl0_CustomerRegister®password
going to try to match with 
_ctl0_MainContent__ctl0__ctl0_ConfirmPassword with JS or html maybe?

big 5 left besides picture
1 password match with con
2 same as shipping option 
3 email pop up - check 
4 shipping tax line and sub total val line
5 go to cart

help doc - hover over link to view path

-- js found using 
/* Script for SelectTopNRows command from SSMS /
SELECT TOP (1000) [ID]
      ,[dataFormID]
      ,[name]
      ,[value]
      ,[expression]
  FROM [ENTERPRISE].[dbo].[[DataFormFieldSettings]] (nolock)
  where [name] like '%client%'

-- no rows returned with a value for clientscript which is what i needed in UAT
found results in prod 
like 'onclick=return confirm("Are you sure you want to cancel this order?");'

onclick=return confirm("This email will be used as your login and for ship confirmations");

tax and ship tax using lookup but nothing in tax charges 

'bookmark this page' was in top html dataformtablefieldsettings

new plan for same as shipping
-- add logic in admin script to not require billing flexfields
-- then use javascript to hide and when check appears billing text fields to have separate from shipping

onclick= document.getElementById("_ctl0_MainContent__ctl0__ctl0_CustomerRegister®flexfield9").style.display = 'none';

circle pgp logo make into button for register login? after submit registering have
giant circle button? that or the rectangle sytle big button with logo float top mid or
left mid?

going to recreate catalog structure to example
spray bottles -> parts(nozzle only, bottle only, label only, full set) -> brands

search sql like this
SELECT TOP (1000) [ID]
      ,[dataFormID]
      ,[name]
      ,[value]
      ,[expression]
  FROM [ENTERPRISE].[dbo].[DataFormSettings]
    where [name] = 'topMessage'

or bottom message to find the html put into a data form
to use images or other things that can be per client and not effect everyone

other examples:
<div class="promoEditButton">
<div class="EditButtonsWrapper" onclick="window.location='default.aspx?tabname=POD&n=WebInventoryPODSearch'">
<span class="EditButtons"><span>POD Inventory</span></span></div></div>

<div class="promoEditButton">
<div class="EditButtonsWrapper" onclick="ShowPop(window.top.popup,'frm_opencontrol.aspx?cname=ctrl_form&n=WebInventoryMessageEdit','defpop',500,400);">
<span class="EditButtons"><span>Add New</span></span></div></div>

heres the part of admin script with the link for login after registering
ctype(p.findcontrol("lblConfirmation"),system.web.UI.webcontrols.label).text = 
"Thank you for registering!<p>For future access to the site, please use the email address and password you entered during registration.
<p><a href=http://uat.aerofulfillment.com/eFulfillment/pgpcleaner/login.aspx>Click here to login and continue placing an order.</a></p>"
#BSY #ESTORE 4/24/19 ^^^^  ABOVE STILL AN ISSUE WHY DOES CLEANER POINT TO THIS LOGIN PAGE?

creating button template using c#
example from microsoft
private void InitializeMyButton()
 {
    // Create and initialize a Button.
    Button button1 = new Button();
 
    // Set the button to return a value of OK when clicked.
    button1.DialogResult = DialogResult.OK;
 
    // Add the button to the form.
    Controls.Add(button1);
 }

not using this or above since we can use css
<button type="button" class="block">Go to Cart</button>

private void AfterRegisteredLogin()
	{
		Button buttonReg = new Button();

		system.web.UI.webcontrols.label.add(buttonReg)
	}

going to test this:
a.button {
    -webkit-appearance: button;
    -moz-appearance: button;
    appearance: button;
		padding: 5%;
    text-decoration: none;
    color: initial;
}

this works to make the link appear as a button

now need to pull the top area together using css making a list for what pieces i need to move
search bar - table#_ctl0_MainContent__ctl0__ctl0__ctl0_ASPxCardView1_DXSE.dxeButtonEditSys.dxeButtonEdit.dxeNullText.dxh0
sku sort by - div#_ctl0_MainContent__ctl0__ctl0__ctl0_ASPxCardView1_col2.dxcvHeader
 - or _ctl0_MainContent__ctl0__ctl0__ctl0_ASPxCardView1_HeaderPanel.dxcvHeaderPanel
go back button - div#_ctl0_MainContent__ctl0__ctl0__ctl0_GoBack.dxbButton.dxbButtonSys.dxbTSys
go to cart button - div#_ctl0_MainContent__ctl0__ctl0__ctl0_cart
catalog title - div#_ctl0_MainContent__ctl0__ctl0__ctl0_CatalogName

thinking of lining these up in a line near top to make it feel more like amazon

also found one data form actually using script in the bottomHTML
used by cpg to calculate whats in the shopping cart they way they want it to look

now skipping ahead to catalog page resizing the whole page to get 6 cards/cat items to show on small screen
may need to change how this lays on page once there are 6
table#_ctl0_MainContent__ctl0__ctl0__ctl0_ASPxCardView1.dxcvControl.dxcv
which is the main div holding the table with all cat cards

heres individual cards
div#_ctl0_MainContent__ctl0__ctl0__ctl0_ASPxCardView1_DXDataCard2.dxcv
		--card with space/margin between next card and fixed 225px H/W change to 15% each should do most of the work

		div#_ctl0_MainContent__ctl0__ctl0__ctl0_ASPxCardView1_DXCardLayout2.dxflFormLayout.dxflViewFormLayoutSys
			--card from border to border - change to 100%?

			td#_ctl0_MainContent__ctl0__ctl0__ctl0_ASPxCardView1_DXCardLayout2_0.dxflHACSys.dxflGroupCell.dxflChildInFirstRowSys.dxflFirstChildInRowSys.dxflLastChildInRowSys
				-- has 100% to fill card - change to 100%?

need to adjust whole row for when there are less items to align center/ float possibly

manage list in windows nav for drop down of shipping methods to choose in review order
change names there

#estore 3/26 - 3/27/19
IIS redirect 

#TIMELOGGING
estore p2 14321
estore p314885 or 855
estore p4 14928

create page in IIS base nav site and registration

2 different pages

changing new order link 
-- this table in enterprise is where you find what these are pointing to link wise
-- find correct page to set the href/redirect to in web_tabs
-- this should be able to be set in web config --> module options in windows nav but its broken

testing with this uat link disc-uat.aerofulfillment.com
to point to current UAT estore urls
 remove S from HTTPS???

create/add new website
put in the vanity URL name
then path to folder holding the html index and web config files 
( need to copy these from existing and edit to match new site(mainly just index to edit)) 
transferring files between dev and prod can use shared drive \\UATWEB02\Websites

once new sites have the correct files in the folders need to edit host file to test
go to windows/system32/drivers/etc/hosts
and add localhost ip configured for websites added

192.168.21.113 www.pgprostore.com
192.168.21.113 www.shoppgpro.com
save that and going to that url locally in browser should redirect to url in html index file


select *
from ENTERPRISE.dbo.Web_ModuleSettings
where fulfillmentid = 521

-- update ENTERPRISE.dbo.Web_ModuleSettings
set SettingValue = '~/default.aspx?tabname=Catalogs'
where moduleID= 119
and FulfillmentID = 521
 
moving data form and some other changes to prod windows nav from uat nav

still need to do tax/ shipping / handling charges from uat to prod
also still need to move over admin script changes from uat to prod


#estore 3/28/19 - 4/24
-- deploy from uat to prod use these tables and procs and views
can deploy the catalog pages today by looking at UAT sql pages for web
web_module
web_tabs
web_module def

catalog man
catalog config
catalog

and set/ insert or copy over to afssql



then web_fulfillment to update layout to new css page

use create to script from uat and change to prod
for tables/ views

follow deployments notes in tech spec under catalog 2.0



    display: -webkit-inline-box !important;
    width: 41%;
    position: relative;
    margin-left: 15% !important;
    margin-top: 4%;

#estore 3/29/19
still need to add little note/ identifier for alerting customer of shipping min charges Y 4/3

first start for new fulfillment have to create master catalog for config/manager
hard insert through DB for master catalog record currently a bug/feature?

random note from dallas group
DMA data mapping analysis

in cpgr blue bodycontainer width by pixels is force set along with margin auto for left right
causing div/forms to sit inappropriately
also right col has px width and margins set which isnt taking the aero11?


margins for smaller screens (720)(768)
catalog page title
catalog title placement and remove master catalog title
adjust these to above search bar

registration page needs to load JS correctly
and (optional) label sitting incorrectly to left

PROD TABLE INDEXES
username / email pop up - works now #BSY caching issue 4/24/19

paperless billing - list id issue

remove cancel button
click to login clear cache
add label explaining Purchase order format
Forgot Password not capitalized

placement of go to cart and go back for 720 res

remove still covered cart view
data form for list for shipping and handling charges
take a note again
a different note
shipping and handling spacing on order view

lining around cant ship to APO note

add a note

a different note

label / alert for min ship amount

#estore 4/17/19
this is on next weeks sprint ATP-14632
finish small parts for estore



#estore 4/24/19
1 Confirm verbiage with Andrew on PO dropdown - N
2 Change wording of CV credit card number to make it more universal (not always on back of card; not always 3 digits) - N
3 Confirm taxes will only be on the Quickbooks page and if so, put a note that the total seen does not include tax - Y
4 Add terms and conditions agreement option to registration page (Take wording from microsite) - Y
5 Remove PO field on registration - N
6 Change "Paperless Billing" to have logic for (PO billing Y/N) and (If yes, then Paperless Y/N) - N
7 If transactions is $0.00, allow for dropdown option to say "Payment Not Required" - N
8 Create a tree on catalog that shows filtering out of catalogs similar to when selecting a hotel or shopping for cars.  Options to select or de-select catalog categories
9 Create logic that shows how many items are left when filtering out criteria - N
10 Ben to set up time with Abby and Carla to walk through catalog management - Y
11 P&G may ask Aero to provide or create generic artwork for catalog categories - N
12 Test email tracking that it works - N


lookup how to get abby's user role set up to view config and manage pages

deployed other CPG change to UAT - dropdown ship method
steps
test in local
always make sure to have UAT merged from master and also the new branch for ticket changes merged from master
this reduces discrepencies so we dont overwrite or overlap / revert changes from someone else

next once everything looks good there should only be the specific things you worked on in the commits
/push 
so now you can pull the changes
then merge ticket branch in UAT branch

here is where you deploy to UAT
right click efulfillment and rebuild sln in VB
create 2 new folders in your own directory 1 for old UAT dlls incase we need to roll back changes
andd 1 folder with the new dlls made locally (copy your local ones here and then copy these into UAT)
copy the new dlls sorted by date modified (should only be 7) over the existing ones in UATWEB02
in order to copy over remote to UATWEB02 server and open IIS and stop the efulfillment in app pool

once copied over the changes are deployed in UAT

1 item we want to add pulled from DEMO -- find where this goes in our code
<dx:LayoutItem Caption="Show Summary">
                        <LayoutItemNestedControlCollection>
                            <dx:LayoutItemNestedControlContainer ID="LayoutItemNestedControlContainer7" runat="server">
                                <dx:ASPxCheckBox ID="ShowSummary" runat="server" AutoPostBack="true" />
                            </dx:LayoutItemNestedControlContainer>
                        </LayoutItemNestedControlCollection>
                    </dx:LayoutItem>

2nd item with all the filter settings -- where does this go
doesnt look like its under sorting data or grouping data or filters specifically - maybe on wrong view of demo

develop filters in VB

#estore 4/25/19
idea for catalog card structure if we end up using that style still --
-- create 2 or x blank ones to offset others on first line
-- cory may change this structure in general though 

fix shipping charge expression to ignore shipping charge  if item cost = 0
#

#estore 4/26/19
Throw New System.Exception({OrdersEdit.order_amt})
#VBA #throw

added the note for * Tax not included in bot html since dataform is a grid
may change

fixing charge


function payDisplay() {
	var p = document.getElementById("_ctl0_MainContent__ctl0__ctl0_CustomerRegister®flexfield3");
	alert(p.options[p.selectedIndex].value);
	if (p.options[p.selectedIndex].value == 1){
		document.getElementById("_ctl0_MainContent__ctl0__ctl0_lblflexfield25").style.display = 'block';
		document.getElementById("_ctl0_MainContent__ctl0__ctl0_CustomerRegister®flexfield25").style.display = 'block';
		document.getElementById("_ctl0_MainContent__ctl0__ctl0_lblflexfield1").style.display = 'block';
		document.getElementById("_ctl0_MainContent__ctl0__ctl0_CustomerRegister®flexfield1").style.display = 'block';
	}
	else {
		document.getElementById("_ctl0_MainContent__ctl0__ctl0_lblflexfield25").style.display = 'none';
		document.getElementById("_ctl0_MainContent__ctl0__ctl0_CustomerRegister®flexfield25").style.display = 'none';
		document.getElementById("_ctl0_MainContent__ctl0__ctl0_lblflexfield1").style.display = 'none';
		document.getElementById("_ctl0_MainContent__ctl0__ctl0_CustomerRegister®flexfield1").style.display = 'none';
	}
}

still need to create logic to make sure default isnt selected


#estore 4/29/19
Email will be used as your login
placeholder 


#estore 4/30/19
test sku for emails have to test emails in prod

test reg code for emails 100 disc is 
3C52 ACSS 9D0 T1T3 - 3C52ACSS9D0T1T3
COE + PREFD + DISC + ROLE
can use any sku this way
biz ret - 3C52
ful serve - 234F
HC - 3D56
HC BG - 456J
HOSP - 1M24 ------ 1M24PGPD0FBT1T3
LIM res - B123
rest - 52L3

meeting notes:


could research where how who orders are coming in from looking at diagram
top level no actual image
bottles - title = pic of words
catalog name is the short desc

standard desc on cat and sub cat to filter on

cat structure slides 1 and 2

opl supermarket etc only match 1 for 1 no dupes
all others can go beyond

change to catalog sku groups? to facilitate the filtering change
slow loading 10 sec + thousands of items
import data to catalog manager make sure it matches and then assign roles/groups

could possibly separate by security roles
duplicate catalog trees to help separate items

sec groups												break down discounts by sec group?
tide dry 16
mww (dtr), house, supmkt majority 1k
opl (fst), house, supmkt majority 2k
all consum 200ish duncan wegmans public restaurant - cust catalog
all- all admin abby MSNP 3k

couple of ways for shipping with or without full freight based on item cost
10 groups to manage

import huge list of items for new user group
dupe this import for 2 dif security groups

be able to match or track through keywords and item master.
dont want to dedicate a flexfield 200/3k
question for solvoyo? where does it land for item master, how are they going to manage

boomi job to have solvoyo pass excels to update new items into catalog
how do we do approvals?

tide asap

2 weeks later DTR init free - manually update their discounts or security group

6 weeks later NSO / field service tech - consumable? 
-- go into restaurant offer to replace and get work order is placed after bill to is loc their at
ship to is their own car stock - field for work order number gen by NSO system
discount ^ ? full price full freight
no bill for their car stock?
cust email?

service call - charge and part
item called service

need to quote above changes to get boomi job for updating inventory
need to quote out above changes for FST or consumables for work orders, discount, no bill, cust email -
-- changes to this boomi job for QUICKBOOKS
need to get tide running and set more changes before next tues

CI project for P4 changes

1 get items from abby broken down per security group and add to UAT catalogs
2 create export and import catalogs to get all security groups set up and test in UAT then copy to prod
3 create new fields for NSO/FST on cart, review, and checkout pages -- test in uat then move to prod


2 dif atps to log these to? 

#ESTORE 5/3/19
use flexfield59 for new field









#ESTORE 5/6/19

use this query to help update catalogs permissions quickly
be very specific with parent_id where possible but also the id


--update nc
	set role_ids = ',590,602,'
--select *
from mason.dbo.New_Catalogs nc(nolock)
where parent_id = 174
--[name] = 'Tide Dry Cleaners'
order by id

#tide go live prep
reg code for tide
1M24PGPD0FBT1T3

2nd code specific for tide PROD
1A2BTIDC0FBT1T3

test code for end user
3C52ACSS0FBA3D3

ma25KE#%

Fall#9375

other helpful tables/views

select *
from ENTERPRISE.dbo.Web_Modules (nolock)
where Fulfillment_ID = 521

select *
from ENTERPRISE.dbo.web_panels (nolock)

-- chris saw issue of validation when using code above took to home order page
then clicking catalog showed catalog manager
also couldnt get to the catalogs itself

-- major caching issue
-- looks to be resolved
-- need to get all images



flush manifolds
price
03537755 - flush manifold
2 port add on

#estore
5/31
make sure to set PO roles allowed in payment setup

find why tracy is seeing wrong price for pump part 03536427
shows 1272.58 but they were quoted 848.39

is actually jeff not tracy, thats why

jeffs cust id 1390351
where are my notes on fixing tracis issue?



begin tran
 update ce
set role_id = (select role_id from mason.dbo.CustomerEdit where customer_id = 1017476)
--select *
from mason.dbo.CustomerEdit ce(nolock)
where fulfillment_id = 521
and customer_id = 1390351
select * from mason.dbo.CustomerEdit ce(nolock)
where fulfillment_id = 521
and customer_id = 1390351
rollback


select (select role_id from mason.dbo.CustomerEdit where customer_id = 1017476), *
from mason.dbo.CustomerEdit ce(nolock)
where fulfillment_id = 521
and customer_id = 1390351

CANNOT UPDATE VIEWS

correct version here
vvvvvvvvvvvv
update ce
set role_id = 1603
from enterprise.dbo.Customer_Fulfillment ce
where fulfillment_id = 521
and customer_id = 1390351

begin tran
 update ce
set role_id = (select role_id from enterprise.dbo.Customer_Fulfillment where customer_id = 1017476)
--select *
from enterprise.dbo.Customer_Fulfillment ce(nolock)
where fulfillment_id = 521
and customer_id = 1390351
select * from enterprise.dbo.Customer_Fulfillment ce(nolock)
where fulfillment_id = 521
and customer_id = 1390351
rollback


-- notes for filipe from mason planning about dottys tickets
atp-14347
14632
14648
14821
14820

*
-- #AJAX note
AJAX stands for Asynchronous JavaScript and XML. This is a cross platform technology which 
speeds up response time. The AJAX server controls add script to the page which is executed and processed by the browser.

However like other ASP.NET server controls, these AJAX server controls also can have 
methods and event handlers associated with them, which are processed on the server side.

The control toolbox in the Visual Studio IDE contains a group of controls called the 'AJAX Extensions'

_________________________________________________________________________________________________________
/*							ATP-14282
								SC portal not working shipment request error
								2/26/19 - 2/26/19
heather getting error when trying shipment request through sc portal
see inner exception
wasnt replicating when we tested reprocessing and having breakpoints in sln



2/26 2:23pm
per jerrys speaker phone convo with lady about some phone issue or login issue
about not being able to call or get a hold of someone - could be tami?
she said "josh told me to open a ticket and it isnt going anywhere"
jerry "yeah thats a joke ill just call john or greg(?) from now on"


_________________________________________________________________________________________________________
/*							ATP-14289
								order missing from sunday import for sykes
								2/26/19 - 2/27

check boomi job sunday see 1 error mail sent for this issue

error
{"Message":"An error has occurred.","ExceptionMessage":"An error occurred 
while executing the command definition. See the inner exception for details.",
same thing occurred today for sc shipment request for onnit and aos
james thought these were due to ship method.

will research more in morning


archana re imported which works fine
but becky wants to know what the issue was
-- james think generic connection error


-- new SC PORTAL issue #SC 4/3 bunch of erros in shipment requests
heather tried to run tons of requests through at the same time and seeing many errors of
"The underlying connection was closed" and " The operation has timed out"

still not sure root cause but could be connection issue

disk space issue
update not pushed for prod side
regression testing

how fedex validates on hold vs release

re process and not process on hold?

or let fallout of not transmitting to fedex


afsutil01\C$\inetpub\logs?

timeline 
cory make hold flag change for onnit live yesterday
archana and chuck made it work for rest of fulfills today right before noon
then all these issues started occurring
so it wasnt noticable enough to cripple system until all requests
were being changed to not use their hold flag and start releasing differently?

since flag isnt at 0 could be trying to release things that dont need to be released?



_________________________________________________________________________________________________________

-- talk with wade
-- project to utilize high rise belt and get all fulfills on 3 sys 
-- fill n seal qc and conveyor
-- lanes for fedex, ups, 1pack
-- getting fulfill on and off conveyor project should be easy not act of congress
-- getting interfaces and live reports facing ops so real time issues are shown to themselves
-- more focus on them gives us less time fighting with others and more time building
-- 


_________________________________________________________________________________________________________


nexigen email going to clutter

1128995


_________________________________________________________________________________________________________
/*							ATP-14286
								add zevo to pipeline report - billing
								2/27/19 - 

searching through billing reports in boomi and proc
then tables for billingpipeline_new
then at crystal report then table fulfillment orders type
finally james found at top of proc for billingpipeline_new
correct source to configure fulfillments in Billing_Preference

have to manually add to billing pref table with insert entries for zevo


select top 10 * from [Billing_Preference] where	short_name like '%tle%' --fulfillment_id = 1166
select * from ENTERPRISE.dbo.fulfillment (nolock) where short_name like '%tle%'

--insert into enterprise.dbo.billing_preference
select 'WH1' as whse_id,
	1166 as fulfillment_id,
	'ZVO' as short_name,
	'Zevo' as long_name,
	1449 as report_id,
	'Transaction' as detail_level	,
	1 as excel	,
	0 as exceldata	,
	0 as pdf	,
	0 as case_bill	,
	0 as pallet_bill	,
	NULL as option1	,
	NULL as option2	,
	NULL as option3	,
	NULL as option4	,
	NULL as option5	,
	NULL as option6	,
	NULL as option7	,
	NULL as option8	,
	NULL as option9	,
	'2019-03-1 03:56:20.203' as add_date	,
	'ben.yurchison' as add_who_name	,
	'2019-03-1 03:56:20.203' as edit_date	,
	NULL as edit_who_name


-- do above insert for each report id seen from matching fulfil
-- NOT NEEDED FOR THIS INSERT from [Billing_Preference]

redid same inserts above for VARTA on 3/22/19


-- using this below from Cory. have to add this to fulfill props. not sure why

use enterprise
aeroadmin
@dmin3900
select * from fulfillment_properties where property_name = 'shipper'

--insert into enterprise.dbo.fulfillment_properties select
	1167 as fulfillment_id,
	'FEDX' as property_group,
	'SHIPPER'property_name,
	'AFS_Varta' as property_value,
	getdate() as add_date,
	'BSY' as add_who,
	getdate() as edit_date,
	'BSY' as edit_who


_________________________________________________________________________________________________________
/*									ATP-14316
										RA0000045324 qty of 6000 available in inventory but zero shipped
										ras
										3/1/19 - 

91571068 
ATP-14316
lineitem trans


_________________________________________________________________________________________________________
/*									WEEK OF 3/4

-- finish from last week - 
-- 1 TAOS GP tests
-- 2 varta zevo license and child meter setups in prod - UAT label test
-- 3 Revise HelpDesk infographic
-- 4 ESTORE CHANGES
-- 5 follow up with stites email. need to get someone here asap, talk through with josh or filipe

config as fedex web services
varta fedex webservices 654740631

_________________________________________________________________________________________________________
/*									ATP-14322
										Team having an issue where error IP already being used
										AERO
										3/4/19 - 3/4/19

Emily having issue with this error						
"WINDOWS HAS DETECTED AN IP ADDRESS CONFLICT
ANOTHER COMPUTER ON THIS NETWORK HAS THE SAME IP ADDRESS AS THIS COMPUTER. 
CONTACT YOUR NETWORK ADMINISTRATOR FOR HELP RESOLVING 
THIS ISSUE. MORE DETAILS ARE AVAILABLE IN THE WINDOWS SYSTEM EVENT LOG."

seems like her computer was just having trouble renewing its lease. shouldnt happen again


_________________________________________________________________________________________________________
/*									ATP-14276
										Ava tax not calc correctly in quickbooks for taxable customers
										AERO
										3/4/19 - 3/4/19
Just put in to review. asking james if this is only configured through quickbooks may be 
more of a ticket for him.

documented in confluence at least partially


_________________________________________________________________________________________________________
/*									ATP-14298
										New return label for sku RLSTOCKC
										
										3/4/19 - 3/4/19
need to verify/research if this is hardcoded in legacy or set to pull return address from
what is given. likely isnt doing it the easy way so may need to see how itll need to be changed
and estimate time to do so.


_________________________________________________________________________________________________________
/*									CI-282
										944 testing against 943 for 3 diff scenarios
										aos - RAS
										3/4/19 - 3/4/19
loc 
0088001010
lot 04 date

lot 08
017A19-098020

lot 09
10000797

wont let me rec more than expected?..

fixed itself. likely a bug in infor

getting anything to go shipped in navigator with cory's new status needs extra actions
that arent seamlessly automated yet. need to be allocated in infor then run lineitem
status update then create manifest with query from cory then run lineitem status update again
and also 'WC - Packed Orders Validation' once it gets to packed. afterwards will likely
need to run lineitem status update again. 


_________________________________________________________________________________________________________
/*									ATP-14337
										we cannot print from mailshop to new printer in cx dept
										aero
										3/4/19 - 3/4/19

fixed issue for barbra and kelly. had to change def on rdp and add in local and set to def

will have to do same for karen and possibly others tomorrow


_________________________________________________________________________________________________________

-- ESTORE changes
-- mostly data form driven

_________________________________________________________________________________________________________

-- notes 
-- write design docs - write what you want to are designing
 - effective time less waste
-- APM wins high apm proves much more work than most else.
 - one submission of code per day
-- check ego

-- debugging think like scientist
-- create hypothesis and test it
-- create a sep hypo and test it as well
-- reproduce bug locally
-- 


-- create solutions for client or systems that require that team or 
group of people to figure out how it works or does not work and use as a test
-- basically creating your own test environment real time and using that real time
-- climate to drive the need to make it work.

_________________________________________________________________________________________________________

task scheduler restarts on afstms01 every day at 4am and isnt supposed to. turn off tomorrow morning 3/7/19


_________________________________________________________________________________________________________

										week of 3/11 
estore changes and prep for meeting tues

-- steps for adding pure to conveyor? 
-- list of what actions needed are for both us and OPs
-- RAS UAT edi tests
-- wella site
-- varta / coty moved to prod/afstms for licenses and child meter setup (documentation)

_________________________________________________________________________________________________________
/*									ATP-14390
										update wella school program site with message. copy data down to aero
										WEL
										3/13/19 - 

need to find a safe way in and safe way to copy data

confluence has info for logging in but not all is viable with site attack

-- pull down data/copy prod site data for wella school prog onto aero
-- put data from dev onto prod site and make sure redirect links work

dev is schoolprogram.ca (canada)

-- how do i do this without compromising our security? crawler bots or etc.

can proceed into sites

dev admin site works with dev admin pw in keepass

not entirely sure how its all strung together but it looks like the
attack compromised the revbase site? and possibly just the front end of schoolprogram?

how do i take the downloads/zips and get them into a working state for prod site

able to login to dev sites and phpadmin
unable to access wellaschoolprogram.com and revbase due to being disabled/ put offline

redirect manager can help fix links/redirects once site is fixed - in admin -> redirect admin
components redirect
joomla compromised on prod
jacked up screen on global config --> site
@dm1n
B!ngCr0sby
B!ngCr0sby@tY0urC0mm@nd

josh said only revbase was ransomware'd so we should only need to copy over
and upload and make sure it looks good?

so basically i should just be able to copy what we have in dev admin to prod admin
how do i access prod admin when it says its down due to domain name?

by pinging the CA site and prod site they have 2 dif IPs so we thought they still might
be part of the same mediatemple or plesk site

after using SSH to look at directories it was hinting at them using different directories
since IPs are also different so we can do the method of copying dev site data
to the prod site. 

so after conferring with team we think we really are missing the dev site piece of
mediatemple and plesk which we then called mediatemple support to try to figure out 
but they cant give us anything because we are the original owner and not listed.
all we could do was have them email him to add us to the list so we can get accesss.

afterwards we resorted to just removing the bad users from hacking and then flipped
the correct PHP file back to the site landing page. for now its the appropriate bandaid


Adnan messaged back saying SSH into dev works? not entirely sure if it is dev or prod
though. will check. otherwise he explicitly stated he isnt getting paid and will
start refusing to help since we havent shown any intent to compensate for this work

-- he did not mention the user authorizing through media temple... so i assume hes refusing
to assist in this step

able to login to mediatemple admin but doesnt look like our goal of plesk dev vs plesk prod(have access) 
unless they are the same? 
#BSY 4/18/19
anyways josh wants me to set up auto backups if they arent already on


/var/lib/psa/dumps 
dir of backups. full backup weekly. daily backup incre

_________________________________________________________________________________________________________
/*									ATP-14418
										CPG estore product demo
										cpg
										2/28/19 - 3/14/19

for documenting travel time for project going downtown.										

start meeting setup notes
2 different versions
we need to use start meeting team
info in keepass for login

quotes for URLs for PGOC through go daddy

also make legend for button template for CSS for all customers as change for PGOC

_________________________________________________________________________________________________________
/*									ATP-14433
										ATK order import failed
										ATK
										3/14/19 - 3/21/19

missing req fields caused import to fail.
they have a master import process that you have to dig through to find the right
import. otherwise the base import wont show all the different types of imports
where errors could be occurring

make sure for splits/ parts that arent master you take filter off after getting specific time frame
where master ran.

then filter by time and should be able to find error by master
make sure to download file that has the error, so dont click successes haha



_________________________________________________________________________________________________________

asset mngmt software

make model
-- age (will populate when software is used)
-- serial ^
- plan to roll out for purchasing, staging, setup, apps.
office = dock and 2 monitor setup

excel list

email aero users screen shots of how to find model number on pc
have them email me back. this is to reduce manual effort required

laptop quote atp

-- consulting service for AWS
-- citrix? as400?
-- soft tokens and multi factor authen

-- how do we load up brand new hardware with all the programs
per user group 
cx, ops mgmt, ops, IT, ETC



_________________________________________________________________________________________________________


testing in VS

end to end testing
what else / kinds of testing do we need to target?


UATINFOR01 192.168.27.24 for rf gun set up for varta test



_________________________________________________________________________________________________________
/*									ATP-14477 & 14478
										afi awi EOM
										AFI AWI
										3/21/19 - 3/29/19
not assigned to anyone yet - in review status


_________________________________________________________________________________________________________
/*									ATP-14396
										dotty not getting batch approval notifications
										CPG
										3/21/19 - /19


_________________________________________________________________________________________________________
/*									IT resource planning meeting
										josh's thurs meeting with CX
										AERO
										3/21/19 - 3/21/19

lydia follow up for 14298
estimate 14447
14240 - PG call center users cant change PW
14387 - CPG
14403 - CPG


_________________________________________________________________________________________________________
/*									ATP-14403
										batch orders showing $0 total - not actual total
										CPG
										3/21/19 - /19

could be tied to the item configuration/setup issue archana was working with?
if the items are wrong the prices could be wrong. not sure where else to go
since other orders arent having this issue
-
according to james this has never worked. they must have only recently started trying to
use it again since james is starting to push more changes for CPG and PGOC

need to find a way to explain this


select *
from mason.dbo.orders o (nolock)
left outer join mason.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
where o.primary_reference = 'CP0001645337'


select *
from mason.dbo.orders o (nolock)
left outer join mason.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
left outer join mason.dbo.wms_PICKDETAIL pd (nolock) on pd.ORDERKEY = w.ORDERKEY
where o.primary_reference = 'CP0001645337'



select top 1000 *
from mason.dbo.orders o (nolock)
--left outer join mason.dbo.wms_orders w (nolock) on w.EXTERNORDERKEY = o.primary_reference
where o.order_source = 'batch'
order by o.ADD_DATE desc

_________________________________________________________________________________________________________
/*									ATP-14396
										dotty not getting batch approval notifications
										CPG
										3/21/19 - /19




_________________________________________________________________________________________________________
/*									MEETING
										WELLA REBUILD
										WEL
										3/22/19 - 3/22/19

touch base with WELLA

40% currently

75% by next week hopefully.

still issues needed to work out. 

1 systems + data with failed backups
	-- sept '17 
	-- 
2 true items up

3 price lists for clairol wella / OPI

-rewards cant be lost
load data for storefronts



_________________________________________________________________________________________________________
/*									ATP-14499
										items on order about to hit stop ship. needs to go out today
										PGOC
										3/22/19 - /19

erin called about this

archana working but may need help


_________________________________________________________________________________________________________
/*									ATP-14493
										have not recvd atk orders today
										ATK
										3/22/19 - 3/22/19

files were imported after ticket was made.
i still spent 15 min verifying they werent sent before then and that they imported successfully



_________________________________________________________________________________________________________
/*									ATP-14495
										missing orders?
										PGOC
										3/22/19 - 3/22/19

the files they said they sent werent not correctly given to us. meaning they didnt upload
to ftp at all.

had to verify the batch today didnt have anything to do with the ones they thought
were missing. and prove that we recvd everything correctly.

then manually executed import so they dont have to wait till tomorrow to get imported



caching issue with web nav header/login images
#BSY varta logo issue 3/23/19
checked afsweb201 afsweb202 and afsweb204 and the files were all where they
needed to be. however james and filipe still couldnt see the images
nothing wrong in windows nav
so remoted into afsweb202 then into iis app pool select efulfill and hit recycle
immediately worked after that


_________________________________________________________________________________________________________
/*									Week of 3/25
										plan and goals
										3/25/19 - 3/30/19

finish CPG estore - mainly sizing for smaller screen / cards

AFI AWI - EOM finish tues.

ASSET MGMT finish finding all laptops and figure out plan for software/app
-- use software josh got quote for but must create write up first
-- to prove its worth to Wade with plan of rollout/.
-- afterwards get PO from accounts payable
-- then start plan to replace qtr of fleet per year.

-- 4/3 should have finalized list of assets and can then write up costs benefit analysis
for wade by 4/5


any leftover varta config for cls /vx controller / child meter

-- update -- prioritize CPG ESTORE
-- finish updates per list and start new excel to drive customer
-- show what all progress we have made and that they should start testing
-- show we are mostly waiting on their end for testing and art assets
-- give them reg codes and specific accounts if needed to test with
-- drive rest of schedule so we can start pushing these changes to prod
-- get with james / josh to possibly make deployment changes sunday night.



-- infor contact info
-- communicating through open case for details on atp-14151 qr scan and android device
* configure new RF for 2D barcode - 1.5hr
* network configuration - 1.5hr
* assuming we are capturing master barcode instead of 40 serials - ? 1-3 hrs

* edi Profile - update this to match desired new structure - then map this data
	and test. - 3hrs

such as
sku
	part1 -> obcd
	part2 -> obcd

or

sku
	part1
	part2

obcd
	obcd1
	obcd2

_________________________________________________________________________________________________________
/*									ATP-14495
										missing orders for sykes
										SYKES
										3/25/19 - 3/25/19

doesnt show an error must go to date/time and look into successful process at the error mail sent

rerun docs which our system will dedupe out all the orders we already have


_________________________________________________________________________________________________________
/*									no ticket
										KNR ship confirm erroring
										KNR
										3/26/19 - 3/26/19

figuring out issue with james. the json error was misleading
had to dig through process and see where it could be going wrong.
view email error sent and looked like incomplete data so clued us in to look
at the map and the sql in the map. used that sql to query what orders are causing issue

found order id / customer ref and found these were made by becky and shouldnt be
caught by shopify order confirm

SELECT
	o.customer_reference				AS 'customer_order_id',
	lf.flexfield20						AS 'customer_lineitem_id',
	l.qty_ordered					AS 'qty_ordered',
	l.qty_ordered - l.qty_backordered	AS 'qty_accepted',
	l.qty_backordered				AS 'qty_backordered'
FROM orders o with (nolock)
INNER JOIN lineitem l with (nolock)
	ON l.orders_id = o.orders_id
INNER JOIN lineitem_flexfields lf with (nolock)
	ON l.lineitem_id = lf.lineitem_id
INNER JOIN Fulfillment_Transaction ft with (nolock)
	ON o.orders_id = ft.trans_key01
WHERE o.fulfillment_id = 1119
	AND ft.trans_module = 'Orders'
	AND ft.trans_submodule = 'RELEASED'
	AND ft.trans_date BETWEEN '2019-03-21 12:30:01.270' AND '2019-03-26 12:30:01.270'
	AND l.qty_ordered - l.qty_backordered > 0
	AND RIGHT(o.customer_reference, 10) > '5804104659'
ORDER BY o.orders_id DESC



SELECT TOP 1 batch_id, batch_date 
FROM Batch 
WHERE fulfillment_id = 1119
    AND batch_type = 'SHP-NOTIFY'
    AND batch_reference = 'KNR-NOTIFY'
ORDER BY batch_id DESC

select *
from orders (nolock)
where customer_reference in ('910082179', '670046926','970090601')

select *
from orders (nolock)
where fulfillment_id = 1119
and email <> 'BECKY.TELLOCK@AEROFULFILLMENT.COM'
and order_source = 'WEB'
order by add_date desc



_________________________________________________________________________________________________________
/*									no ticket
										mason planning meeting
										mas
										3/27/19 - 3/27/19

ticket for report that pulls exclusively by lot needs to be filtered more
as it pulls too many irrelevant lots/locs for users?
old ticket was 12662

										3/28/19 - 3/28/19

issue for CPG with TCD backorders or orders not closing.
"closing orders will help your help customer so its billable"	
not verbatim but something to that effect is what Dotty said josh is telling her
for these TCD orders not closing

greg "i demand technology is on these calls to deal with stuck orders from becoming nuissances
and find root cause. its not an adequate answer and doesnt make business sense to me(in regards
to josh trying to get CPG to pay us to fix TCD dropship orders not closing issue)."



_________________________________________________________________________________________________________
/*									ATP-14539
										companion skus not dropping
										CPG
										3/28/19 - 3/28/19


_________________________________________________________________________________________________________
/*									ATP-14527
										Credit card charge
										aero
										3/25/19 - 3/28/19

#BSY 4/20/19

james figured this out
can search for name and other data matches in cybersource
and also nav using cost on order

he claims its valid so tied to a company or fulfillment that uses cybersource thru us

_________________________________________________________________________________________________________
/*									ATP-14528
										LK10897 stuck in part shipped
										SKII LW
										3/25/19 - 3/28/19

expired lots / shelf life issue. 

can move qty from another lot to pick from or can 0 ship remaining

they moved qty to the loc and lot in infor

then they got error exception caught handling shipping, unable to update lotxlocxid table for lot 
and then i ran fix alloc for this new one and tried to ship the item and it worked
										
_________________________________________________________________________________________________________
/*									ATP-14552
										Team not receiving batch notifications for first batch only batch too long
										CPG
										3/28/19 - 3/28/19 - 4/15/19


select *
from mason.dbo.Fulfillment_Event_Log (nolock)
where event_id = '21'

select *
from mason.dbo.MailEvents (nolock)

select *
from Fulfillment_Subscriptions (nolock)
where event_id = 21
and [subject] like '%CPG%'

server - AFSATOM01

file explorer 
C:\Boomi AtomSphere\Atom - AFSATOM01.Aerofulfillment.com
open file for mason

different sub ids for diff people
ad5700ef-756c-4fc6-8c72-ccdb507b7697 - abby craig
e44f0322-8dc5-454c-b405-c1a56d7ab6ec - dotty s
19e974f6-93c3-49d3-8ef9-8f5aa69756aa - dotty?
5b2c297b-2c5f-40b3-8c86-20612f93c198 - brian 

proved emails are working but also going to use BCC in subs table to email myself
whenever they get CPG batch order waiting for approval emails

also part of atp-14396

confirmed on 4/1 these emails went to my inbox
										


_________________________________________________________________________________________________________
/*									ATP-14547
										LW%1349 stuck please force ship cust already picked up
										LW
										3/28/19 - 3/28/19

force shipping in infor
2 dif lots with shelf life expired
										
_________________________________________________________________________________________________________
/*									ATP-14552
										give matt access to all fairfield fulfillments
										AERO
										3/28/19 - 3/28/19

manually added fulfillments to matts user account
through windows nav
										
_________________________________________________________________________________________________________
/*									ATP-14544
										order OC0002160194 will not allocate item PWR1113
										PGOC
										3/28/19 - 3/28/19

allocation trace to see why it isnt allocating from order.

saw its looking for lot05 and failing

all expired lots no non expired inventory available


 -- update lli
 set lli.ID = '',
	lli.[status] = 'OK'
 --select * 
 --from wms_lotxlocxid lli where lli.lot = '0000265817'
 from wms_lotxlocxid lli
 where lli.lot = '0000265816'
 and sku = 'PWR1113'
 and lli.loc <> 'PICKTO'


doing manual inv move for item
C0130201 proper loc
from loc HMP011803

shipped after this
										
_________________________________________________________________________________________________________

dallas group
notes on manually adding pick detail in infor for items that could have issue 
with how they are allocating.

in allocated status delete line from pick detail then add new 
find proper lot loc with qty >0 and save and itll auto allocate with new dif
allocation.

problem was with zevo or varta order that had a pickuom of 1 or 6 that may not have
been what it needed to be to match rest of pick or allocation.
this way we force it to new allocation

										
_________________________________________________________________________________________________________

										
_________________________________________________________________________________________________________
/*									ATP-14551
										order qty and task qty dont match
										ATK
										3/28/19 - 3/28/19
TK1349063

according to matt pick ticket is showing just the one task as the total

need to see why this doesnt match infor qty

task detail in infor shows 2 tasks for 1 qty each. possibly printing issue or 
data source issue for pick ticket

4/2 #BSY need to cont work on this

										
_________________________________________________________________________________________________________
/*									ATP-14504
										Please remove the "Add to the Current Order" button from the View Existing Orders tab
										in Windows Navigator. This is billable work
										AFI
										3/28/19 - 4/1/19

under order dropdown nav bar
click view existing orders
bottom button needs to be removed. not sure if this is tied to admin script or data form etc
data form looks to be WebOrdersViewInformation

html file is ctrl_RecentOrderDetail.ascx

possibly use css or JS to hide the element 

for css
a#_ctl0_MainContent__ctl0__ctl1__ctl0_igmbtnAddToOrder.SubmitBtn
can probably use this for JS in function to hide but not sure how to validate or
write logic to check for the page its on exclusively for AFI
document.getElementById(_ctl0_MainContent__ctl0__ctl1__ctl0_igmbtnAddToOrder).logic


had to hide using visibility: hidden; css for both the a#submitbtn and the div#submitbtn wrapper
to hide full bar

_________________________________________________________________________________________________________
/*									ATP-14558
										following orders stuck in pack status
										ONN
										3/26/19 - 4/1/19

at first look couldnt find order ON43078 in infor at all but found 2 EXD orders

heather never responded. matt stopped by to inquire on 4/1 and it let me ship
this was before i knew or verified anything. turns out it was INTL and didnt have manifest
data created yet.

so the nightly cleanup process shouldnt have fixed it anyways since it
should never have been preprinted due to INTL

anyways used cory's manifest insert for shipped orders 

and this should be closed


_________________________________________________________________________________________________________
/*												WEEK OF 4/1/19
													AERO
													Goals / plans

-- finish more estore go-live depending on what David thinks next steps are
cleanup from notes i took last friday

-- finish finding devices for asst mgmt list
email everyone separately for them
hit windows key and begin typing system information
click this option
email me back both the system name and system model

and then enter rest into sheet.

-- new tickets. 
-- 4/1 completed updating PGOC and AFI sites through Data forms and CSS
-- those tickets are AFI ATP-14504 and PGOC ATP-14447

start working on moving/migrating from old ftp server to new ftp server
-- follow up on email tickets for NARS and CPG
-- atp-14552 CPG - testing if reseting dottys notif to be close to brians if 
she will get the batch pending emails since right now she isnt because
hers is running 25 mins after theirs and they already approve batch 
so it has nothing to send her

-- finish documentation for EOM stuff and other projects
-- such as estore, FTP migration, wella site, etc?

-- wella still waiting for another email back from Adnan, he said he would check friday 3/29
and heard nothing on 4/1


-- finish reworking atp helpdesk infographic
-- #BSY reworked on 4/2 and 4/3 should be finished.


_________________________________________________________________________________________________________
/*									ATP-14447
										remove field - qty avail from everyone but admin &superuser
										PGOC
										4/1/19 - 4/1/19


had to use the copies of the forms that already existed and hide the fields not needed
but also make sure the logic/expressions for the allotment bal was correct. 

also didnt submit for Erin to test before pushing to prod which she went a little wild over
-- admittedly my fault. shouldnt have jsut gone right to prod. client noticed a mistake

-- didnt copy appropriate logic AND didnt set footer value to SUM. overall it did get
fixed but the caching between afsweb201 afsweb202 and afsweb204 still seems to be off
and im not sure why but need to go over notes with how james and i fixed for VARTA
believe may need to go into IIS on those servers?

										
_________________________________________________________________________________________________________
/*									ATP-14542
										Set up wella site to back up from DEV media temple account
										WEL
										3/25/19 - 4/  /19

contacted Adnan who owns the site access to give us the right credentials to DEV
media temple site

he responded on 3/24 or 3/25 with credentials that were in confluence but dont actually
work to log us in. 

i informed him immediately to try to login himself with those credentials to verify
that they work or to reset the password because he must not have seen if they worked
since it wont let us log in.

or for him to call them to give us access to the site by authorizing us as users

he responded on 3/28 that he would "look at it tonight" and today is 4/1 and ive heard 
nothing back yet

										
_________________________________________________________________________________________________________
/*									ATP-14576
										Updating logo on website and packing list
										VAR
										4/2/19 - 4/  /19
packing list img dir:
\\afsweb204\content\wwwroot\SC.Portal\Content\Images\Logos

also through css or data forms for website

adjusted css to make the logo centered and not cramped looking.
tested in uat nav then put in prod

according to cory the SC portal loads the image dynamically for logo
and i shouldnt need to configure anywhere besides pasting image in that folder

so in theory hes saying the logic would update the fulfillment_configurations table
that currently shows image/logo for varta as varta_logo.png and
once the new one is loaded it will update to VARTA_LOGO.jpg?


										
_________________________________________________________________________________________________________
/*									ATP-14541
										MIGRATE AERO SFTP server to AFSMTF02 from 01 decomission old FTP
										AERO
										3/25/19 - 4/  /19

had this project assigned but not needed to start until now. 

basically what we covered on how 01 is slow and need a fresh start without
any crawlers or other predatory network behavior.

decommision old after fully switching over. 

specific to do list/plan of switch over:
list of all users and ips
get copy of firewall policies from peak10
have them add same ones to afsmtf02?
list of apis and etc?
-- can we copy over or preset them up before moving everyone over -- test?
blank (whatever im missing)										

rollout
move clients over officially
ma99RF#%
#migrate #sftp 5/9/19
- need to clearly define cutover plan



_________________________________________________________________________________________________________
/*									ATP-14604
										FW unable to connect to FTP at midnight to send files. resent this morning
										FW
										4/2/19 - 4/2/19

asked Katie what the actual issue was. and they are able to connect just
couldnt last night around midnight 00:15 and this is when we run midnight processes
and also when we experience heavy connection errors due to peak10

inform this is something we are aware of and switching providers soon

										
_________________________________________________________________________________________________________
/*									ATP-14593
										VARTA Top-off report
										VAR
										4/2/19 - 4/  /19

desc:
The top-off replenishment report does not function for the VARTA locations. 
These locations are set in zone z640, but the locations start in aisle 076. 
The range of locations are 0760-001-010 to 076-016-050. This report should work with 
any forward pick, and this is the way that we are replenishing our volume moving forward 
so it will need to work with all clients for all forward pick.

										
_________________________________________________________________________________________________________
/*									ATP-14594
										can we run Catalog update twice in 24 hrs. they asked we increase # of cat 
										updates. is this possible?
										CPG
										4/2/19 - 4/2/19

this deletes catalogs and then updates and inserts to REMAKE/update the catalogs
would be a window during the day where you cant order or view catalogs if we did this

 [dbo].[pr_Process_CPG_CatalogItems]

filipe answered no to moving or changing any maintenance jobs 

										
_________________________________________________________________________________________________________
/*									ATP-14540
										we are trying to rec zevo sku 91956629. seeing it in nav and infor
										not seeing it in commodity setup
										ZVO
										4/2/19 - 4/2/19

searched wms_sku and commodity setup and was able to find it. not sure if there was
any real issue other than the timing it took to appear in commodity setup from
originally trying to receive it.

										
_________________________________________________________________________________________________________
/*									ATP-14571 nav-82
										INTL orders split between aero and TCD - tcd shipped and aero cant
										CPG
										4/2/19 - 4/2/19

when theres a split shipment thats INTL we arent able to ship both
because all cartons must be together for commercial invoicing? 

this may be development or just a miss on something OPS or CX should know to do
changed to nav bug ticket

										
_________________________________________________________________________________________________________
/*									ATP-14612
										VA75643 - INTL stuck in packed
										VAY
										4/2/19 - 4/  /19

this order is stuck in picked not packed.

sql throwing me off possibly, see that in nav orders there are 2 line items
but in infor it shows only one. so chased after that seeing there was
some line or record that was deleted.

select *
from lebanon.dbo.orders (nolock)
where primary_reference	like '%VA%'
and ship_country <> 'US'
and orders_id in (39318982, 39041510) --fulfillment_id = 1163
order by add_date desc
-- o id 39318982 - VA0000075643 2nd 39041510

select *
from LEBANON.dbo.Fulfillment_Event_Log (nolock)
where fulfillment_id = 1162
and add_date > '2019-04-01 16:57:24.933'
and customer_id = 1839612

select *
from LEBANON.dbo.Fulfillment_Events
where fulfillment_id = 1162

select *
from lebanon.dbo.Fulfillment_Transaction (nolock)
where fulfillment_id = 1162
and trans_key02 = '39318982'
order by trans_date desc

select *
from lebanon.dbo.LineitemEdit (nolock)
where fulfillment_id = 1162
and orders_id = 39318982

select *
from LEBANON.dbo.wms_SKUXLOC

select *
from LEBANON.dbo.wms_LOTXLOCXID
where sku = 'WH21BBUS02'

-- lot 0000270929 id 00288741
-- lot 

select *
from scprd.wmwhse1.LOTXIDDETAIL (nolock)
where oother1 <> ''
order by ADDDATE desc


eventually after all that it looked like there was nothing wrong
with the allocation or picking or anything sku/item related.

also kinda looked like a possible issue with order info but compared to another
IL order and they looked too similar for it to not error sooner

looked through this proc after trying to see if vayyar needs to be dock confirmed
which they do i now know,
so im thinking since its in picked and not packed they just missed dock confirming it
ticket doesnt say anything about it having an error
[dbo].[CLS_Manifest_Update]

#BSY 4/23/19
use notes from 14748 with these serials
WH1UCC0U838S1486, WH1UCC0U838S2736, WH1UCC0U838S1369, WH1UCC0U838S4310,WH1UCC0U838S1996,
WH1UCC0U838S4521,WH1UCC0U838S3256, WH1UCC0U838S4303, WH1UCC0U838S2737, WH1UCC0U838S0844

										
_________________________________________________________________________________________________________
/*									ATP-14240
										CPG call center users cant log in. please reset pw or fix login
										CPG
										4/2/19 - 4/  /19

sounds like it could be 1 of 2 things.
1 if its them trying to log in to navigator we can teach
dotty how to fix herself as its not an IT issue to manage her clients PW that she
can easily reset in windows nav.

2 its not navigator and we probably need to webex just to see what and where the 
issue is before we can take any next steps



										
_________________________________________________________________________________________________________
/*									ATP-14592
										NEEDS ESTIMATE - WALMART UCC128 Label Setup
										VAY
										4/4/19 - 4/  /19

needs estimate

										
_________________________________________________________________________________________________________
/*									ATP-14461
										Bug with cust allotment functionality
										COTY
										4/4/19 - 4/  /19
cory put in part of fix. other bug/issue is even though you cant order it now
you can order it using the existing order tool to replace it

going over this with cory and james

pgoc set up differently
order rule should be under line item rule

#allotmentbug
import error still

submit doesnt make it work - cust id instead of name?
consistency with legend in import tool
once file is uploaded using button the
submit and export button show back up - unintended for sure
-template looks good however
allotmentteammanager link to other page


_________________________________________________________________________________________________________
/*									ATP-14462
										slow performance when placing orders 30sec or so
										COTY
										4/4/19 - 4/  /19

james said its only coty
look at data forms for possible filtering or function or expression making it take longer

looked all through data forms and still cannot find the issue that james thinks
is specifically slowing down this catalog. which feels evident.

was going to try to use event on catalog dataform to make a loading message or pop
and after the page completes loading the message goes away
this is one used for emails
'email returns load'
Dim fulfillment_id as Integer = cint(args(0))
Dim customer_id as Integer = cint(args(1))
Dim role_id as Integer = cint(args(2))
dim qs as Specialized.NameValueCollection = args(5)
dim p as object = args(6)
Dim NumberOfDetail as Integer = 10


If p.IsPostBack = False Then

    Dim dsOrder As DataSet = aero60.businessRules.CommonProvider.RunQuery("Select * from Fulfillment_dataEntry where entryid= -1", fulfillment_id)
    dsOrder.Tables(0).TableName = "Fulfillment_DataEntry"
    'For intDetail as integer = 1 to NumberOfDetail
    '    dim dr as datarow = dt.NewRow()
    '   dt.rows.Add(dr)
    'Next
    HttpContext.Current.Session("rETURNdETAIL") = dsorder
 
End If

Return HttpContext.Current.Session("rETURNdETAIL")

'email returns after load'
Dim fulfillment_id as Integer = cint(args(0))
Dim customer_id as Integer = cint(args(1))
Dim role_id as Integer = cint(args(2))
dim qs as Specialized.NameValueCollection = args(5)
dim p as object = args(6)
dim helpstr as string

helpstr="<font face=""Arial,Helvetica,sans-serif"" align=""left"">"
helpstr= helpstr & "<BR><h3>Please follow these guidelines when returning Materials to Aero Fulfillment Services</h3>"
helpstr= helpstr & "<BR />1. Please see the accompanying Material Returns Form below. "
helpstr= helpstr & "<br /><br />"
helpstr= helpstr & "2. Fill out form in its entirety or as completely as possible. The ""From"" address is the address where the materials are to be picked up from.  "
helpstr= helpstr & "If the materials to be returned were ordered for a New Store Rollout or Store remodel, please indicate that in the provided ""Customer Name"" and ""Store Number"" spaces."
helpstr= helpstr & "returned were ordered for a New Store Rollout or Store remodel, please indicate that in the provided &quot;Customer Name&quot; and &quot;Store Number&quot; spaces. "
helpstr= helpstr & "<br /><br />"
helpstr= helpstr & "3. Please list the quantity, Form number (SKU), brief description, and original order number (where applicable) for each item to be returned. Click on ""Add Details""."
helpstr= helpstr & "<br /><br />"
helpstr= helpstr & "4.Click the &quot;Save&quot; button to send the completed form to <a href=""mailto:CPGRETURNS@aerofulfillment.com"">CPGRETURNS@aerofulfillment.com</a>"
helpstr= helpstr & "<br /><br />"
helpstr= helpstr & "5. Once you have completed and submitted the "
helpstr= helpstr & "Returns Form, Aero will send out the necessary Return labels and documentation "
helpstr= helpstr & "<br /><br />"
helpstr= helpstr & "6. Upon receipt of the Return Labels from Aero, it is your responsibility to "
helpstr= helpstr & "complete the following steps to insure the completion of the Returns process: "
helpstr= helpstr & "<ul>"
helpstr= helpstr & "<li>"
helpstr= helpstr & "Make sure the carton is in acceptable condition for shipping "
helpstr= helpstr & "<li>Make sure that the items listed on the Returns Form match the items in the carton(s) to be "
helpstr= helpstr & "returned </li>"
helpstr= helpstr & "<li>Insert a &quot;hard copy&quot; of the completed form into the carton </li>"
helpstr= helpstr & "<li>Seal the carton to insure safe shipping through FedEx </li>"
helpstr= helpstr & "<li>Affix the provided Returns Label - and any other required documentation - to the carton </li>"
helpstr= helpstr & "<li>It is up to you to contact FedEx and schedule a Pick-up of the carton(s) or to drop off the carton(s) at an acceptable FedEx location. </li>"
helpstr= helpstr & "</ul>"
helpstr= helpstr & "7. Upon receipt of the return, Aero will contact you if there are any issues with the process"
helpstr= helpstr & "<br /><br />"
helpstr= helpstr & "8. This is a list of Materials deemed &quot;Non-Returnable&quot; by Procter &amp; Gamble for this process: "
helpstr= helpstr & "<ul>"
helpstr= helpstr & "<li>Metering Tips (not included in complete Kits)</li>"
helpstr= helpstr & "<li>Any Materials/Parts that have been altered from their original condition</li>"
helpstr= helpstr & "<li>Any Materials/Parts that are broken in any way</li>"
helpstr= helpstr & "<li>Any Materials/Parts that are used</li>"
helpstr= helpstr & "<li>Any Materials that did not originate from the Aero Fulfillment Warehouse </li>"
helpstr= helpstr & "<li>No Lightbulbs</li>"
helpstr= helpstr & "<li>No Manuals</li>"
helpstr= helpstr & "<li>No Wall Charts</li>"
helpstr= helpstr & "<li>No Ink Cartidges </li>"
helpstr= helpstr & "<li> ** note - this list is subject to changes on a "
helpstr= helpstr & "regular basis </li>"
helpstr= helpstr & "</ul><br />"
helpstr= helpstr & "IMPORTANT - If your returns contain any Lithium based batteries or tools, you must note this on your initial submission of the Materils Returns Form - documentation will be sent along with the Returns Labels If you have any "
helpstr= helpstr & "questions, issues or suggestions for this return process, please submit them to <a href=""mailto:CPGRETURNS@aerofulfillment.com"">CPGRETURNS@aerofulfillment.com</a>"
helpstr= helpstr & "</font>"

ctype(p.findcontrol("plaHelpText"),system.web.UI.webcontrols.literal).text=helpstr

If qs("cpt") = "1" then
    ctype(p.findcontrol("pnlConfirmation"),system.web.UI.webcontrols.panel).visible = True
end if

probably more accurately this usage in reorders for CPG

'reorder edit submit'
Dim custom_roq As String = HTTPContext.Current.Request.Item("_ctl0:MainContent:_ctl0:_ctl0:Event_InventoryReorder®custom_qty")
Dim custom_vendor_price As String = HTTPContext.Current.Request.Item("_ctl0:MainContent:_ctl0:_ctl0:Event_InventoryReorder®custom_price")
Dim reorder_comment As String = HTTPContext.Current.Request.Item("_ctl0:MainContent:_ctl0:_ctl0:Event_InventoryReorder®reorder_comment")
Dim trans_status As String = HTTPContext.Current.Request.Item("_ctl0:MainContent:_ctl0:_ctl0:Event_InventoryReorder®trans_status")
Dim reorder As String = HTTPContext.Current.Request.Item("i")
Dim sql as String = ""

If custom_roq = "" Then
	custom_roq = "NULL"
End If

If custom_vendor_price = "" Then
	custom_vendor_price = "NULL"
End If

If reorder_comment = "" Then
	sql = "Update inventory_reorder set custom_qty = " & custom_roq & ", custom_price = " & custom_vendor_price & ", reorder_comment = NULL where reorder_id = " & reorder
Else 
	sql = "Update inventory_reorder set custom_qty = " & custom_roq & ", custom_price = " & custom_vendor_price & ", reorder_comment = '" & reorder_comment.Replace("'","''") & "' where reorder_id = " & reorder
End If

If sql <> "" Then
Aero.BusinessRules.CommonProvider.RunQuery(sql,73)
End If

If trans_status = "5" Then
return "alert('Reorder Updated.'); closeDefaultPOP();window.top.location = ""default.aspx?tabname=ReorderApprove"""
Else If trans_status = "7" or trans_status = "8" or trans_status = "6" Then
return "alert('Reorder Updated.'); closeDefaultPOP();window.top.location = ""default.aspx?tabname=ReorderView"""
Else
return "alert('Reorder Updated.'); closeDefaultPOP();window.top.__doPostBack(null,null);"
End If


If trans_status = "5" Then
return "alert('Reorder Updated.'); closeDefaultPOP();window.top.location = ""default.aspx?tabname=ReorderApprove"""
Else If trans_status = "7" or trans_status = "8" or trans_status = "6" Then
return "alert('Reorder Updated.'); closeDefaultPOP();window.top.location = ""default.aspx?tabname=ReorderView"""
Else
return "alert('Reorder Updated.'); closeDefaultPOP();window.top.__doPostBack(null,null);"
End If

-- this piece is in the onaftersave event on data form ReorderCreated in CPG
closeDefaultPOP(); window.top.location.reload()

-- this is the panel id for the catalog page its going to from coty home.
/efulfillment/default.aspx?panelid=2&tabindex=0&tabid=1&
above code im trying to utilize to display a message for loading.									

so if i use an if like above
i cant just use a table field name like trans_status
i need to be able to leverage JS or something where its loading a form

so maybe this type of JS... 
function onLoadLoading(){
if onLoad(document.getElementById(catalog item here)style.display =='none'){
		return "alert('Loading.. Please wait.')"
}

}

or 

function displayLoad (){
	do while()
}

_________________________________________________________________________________________________________
/*									ATP-14460
										SKUs not included in Inventory Balance File
										NARS
										4/4/19 - 4/4/19
checked our boomi process documents from inventory balance file
both the data pull and the mapped and transmitted data shows all the skus in
question
0607845001225
0607845001232
0607845024859
0607845024965
0607845024972
0607845024989
0607845092452
0607845092469
0607845092476
0607845092490
file name NARS_US_INV_20190403_204901.xml

										
_________________________________________________________________________________________________________
/*									ATP-14565
										estimate changes for discover SL
										DISC SL
										4/4/19 - 4/  /19

meeting with johnna and katie

fedex api call to remove manual work of CEs of going into fedex looking up order
and then manually printing return label
-- should be easy to automate using boomi and api calls to fedex labels api endpoint
per lydia

2nd change request regarding ship date on data form for order
it is using drop date and its confusing for customer to measure this against ship method

-- change verbiage or change field altogether to use est ship date
-- something to make lining up date they want deliv by with the ship method they want to use
-- or just adding logic to shipmethod conditions in back end based on date they want
-- deliv

#BSY 4/9/2019
talk to cls or figure ourselves if in cls it can generate return label
how does it get in box for order already packed and sealed.
print config rma doc on ship station
pass back on tms int based on item or rma doc

submitted through nav. admin script could scroll through and set flag automatically
on flexfield

something similar with pgoc

config RMA doc be able to know how to pass in params into cls as doc flag

boomi job order mapping

#BSY still need to follow up with CLS 4/29/19
on if they can gen return label and how itd work

#BSY atp-14565
from cls on 5/1/19
Hey Ben,

Thanks for emailing this one in from our phone conversation previously.

This may be completely supported with existing functionality, and if you can test against the CLS DEV server you may be able to accomplish this today.

You would send a second SHIP_REQUEST with the same information, however add the <RETDEL_FLAG>, set to “1” to each package on the shipment. 

This will indicate it is a return delivery, and adjust the label/information as necessary. 

Let me know if this helps clarify and how we can help further for this process. 


5/6
I spoke with Chuck a bit on this one, and I apologize as my initial response was specific to black box.

For the client this can all be performed manually (by adding the appropriate fields to the interface), however that would require some testing to determine if it will let you reload a shipment, then manually mark fields, or if the shipment data would need to be re-entered. It would effectively be a second manual “shipment”

However it sounds like you are asking for a way to load and trigger this automatically in the client. This would be take some investigation to determine the level of effort, likely some additional data loaded from aero via stored procedure, and ultimately a work order to accomplish getting this process automated in the client.

Let me know what your thoughts are on this. 

5/8
Ben,

This will involve a lot of discussion to proceed, but initially –

It would involve you to pass a new custom field (via your stored procedure) for example “ARO_RETURN_LABEL”; this field would indicate we need to perform logic to generate a duplicate shipment with the correct fields set indicating a return delivery shipment (and label) is required.

After some discussion we believe this to be 40 hrs of work, or approx. $8000 of custom coding and logic. 

Some initial questions that could impact the scope – 
1.	We would either be returning no information back to your host for the return shipment, or we would need to map it in a way outlined by Aero, as the shipment identifying details would be duplicate to the initial shipment.
2.	On hold shipping would not be supported for the return.
3.	How would these returns be voided if needed?
4.	Can shipments from your host be pulled multiple times?


An alternate less automatic options which would decrease the scope significantly would be as follows.

A package is shipped that requires a return delivery label. The user clicks a toolbar button indicating a label is needed for return. The user would then rescan the shipment/package, generating a return shipment.  This assume that #4 above is true. 

5/16
Good afternoon and thank you for your patience!

Josh and I had to review the options CLS gave us and then present our solution to Filipe to hear what he thought.

So we will start from there:
•	CLS has a solution to fully automate a process for us to get an order and set a flag that it needs a return address and then it will generate once the standard label is printed. This method is a fairly good solution and aero also has one of our own.
•	We could implement a similar logic but leveraging our smart connect system to use a flag or a field value that DSL will pass to us on their orders. Then our system reads that and generates an extra label using a system we created(better value).

The biggest question actually needs to go back to the client at this point in that we don’t know what drives or determines which orders need a return label or not? Where do we currently get this information from the client, and if we don’t how can we ask that they send it in a field on an order level?

We need to understand this because we need to be as automated as possible. We shouldn’t need to ask more from our wavers, pickers or cx team to go and identify these orders manually as this would be considered more work than just an extra pick, which will already be part of this request as 2 labels with different uses is a separate pick.

If the client would like to get on a call with Josh, Filipe and I we can discuss this further.


6/12
somehow got lost in translation that they are using conference orders to determine what gets
the label or not.
need to validate with customer that all skus in this catalog will need return labels
then we should be able to finish qouting and that should give us the 2 options we need to send to
DSL as solutions


										
_________________________________________________________________________________________________________

												WEEK OF 4/8
												GOALS AND EXPECTATIONS
#BSY goals 
continue work on following projects
-- high priority
-- ESTORE
	-- finish changes from 2 fridays ago notes for prod
	-- start new changes from marks/davids notes during follow up
	-- develop 2 new changes for implementation through devexpress
	 - check boxes for filtering like buying car or other online stores
	 - showing search results for items filtered near top of screen

-- ASSET MANAGEMENT
	-- notes from meeting with josh, wade, chris
	 - specific new laptops to specific people by dept
	  - first wave IT/exec/brenda/waving
		- cascade above groups old laptops to next group after cleaning /reimage
		- get lansweeper if annual
		- price all	assets out through CDW and TSG discounts
		- detail every specific expense to where its going and why down to names
		 and cents. need to show where its going as clear as day.
		- list all in excel: laptops, desktops, projectors, meeting room cal devices, monitors, 
			stands, docks & phones
	 - need to be able to nail this down and present in front of execs with Wade by next friday 4/19
	 - create powerpoint to show the specifics with how this gives major updates to many depts
	 - Your cleverbridge reference number: 171385230

-- powerpoint layout
slides start with presenting to execs what we want with just bullets and etc
then on same slide use animation to pull in pic with text on it
to show the product but also how much it is not only price but cost to company ie 
resource usage to set it all up

pretty simple and should be effective but do i create picture edited with text on it or is
it same amount of work to just use keynote to do that?

Overlay with text details like above as part of pic.
also potentially add asset manager software in keynote.
add pic overlay for 4 year roll out page with pic style same as above but as a graph
of cost going down from first year



-- Migrate aero SFTP server to AFSMTF02. Decommision old SFTP
	--	 	 											

-- COTY TICKET ISSUES
-- atp-14461 & atp-14462
	-- allotment issue 
		looking through emails from kim and corys work it looks like he left a bit unfinished
		at least from what the excel sheet open issues were showing
		otherwise i cannot tell at all where his changes are


	-- slow catalog loading issue
	for sure this is a coty specific issue for catalog page
	cant find in data forms yet where its caused though

-- new tickets
-- atp-14470 adding couple fields and pulling data from orders to varta windows and
	web nav prod and UAT

-- 
										
_________________________________________________________________________________________________________
/*									ATP-14679
										remove fedex overnight as a ship method for manual orders
										AERO
										4/9/19 - 4/10/19
remove this for all navigator orders that can be done manually

11004
11005
11011
11012
16001
16007

all the fedex first overnight ship methods. 

update through sql to not allow cx user roles to use this

SELECT TOP (1000) [fulfillment_id]
      ,[ship_method_id]
      ,[role_ids]
      ,[require_ship_bill_account]
      ,[sur_charge]
      ,[bill_role_ids]
      ,[account_number]
      ,[sequence]
      ,[user_description]
      ,[culture]
  FROM [ENTERPRISE].[dbo].[Fulfillment_Ship_Method]
  where ship_method_id in (11004,
11005,
11011,
11012,
16001,
16007)


begin tran
delete f

FROM [ENTERPRISE].[dbo].[Fulfillment_Ship_Method] f
  where ship_method_id in (11004,
11005,
11011,
11012,
16001,
16007)
rollback

they dont need this at all unless its occurring over through boomi or api
from customer directly. no more fedex first overnight in nav at all

#BSY first overnight
turn back on for afi awi and fulfillments that have their own fedex account

look through config service DB


select s.description,i.short_name, f.*
from enterprise.dbo.fulfillment_ship_method f (nolock)
join ENTERPRISE.dbo.ship_method s(nolock) on s.ship_method_id = f.ship_method_id
join ENTERPRISE.dbo.fulfillment i (nolock) on i.fulfillment_id = f.fulfillment_id
order by f.fulfillment_id, f.ship_method_id

-- above used to create list of all fulfills shipmethods

still unsure of how to check what they can use via file feeds/api?

										
_________________________________________________________________________________________________________
/*									ATP-14153
										Return serial scans on XML or API for sku WH21BBUS01
										VAYYAR
										4/10/19 - 4/10/19
cory did the work and showed live vs dev
need to push changes from dev to live

missed two links from component to component

need to reprocess 4 or 5 orders
VA0000076074
VA0000076052
VA0000076151
VA0000076164
VA0000076167
VA0000076152
VA0000076153
VA0000076186

take the get and test in sql 
had to comment out trans status and it worked
so replicated in canvas and was able to get this processed


_________________________________________________________________________________________________________
/*									ATP-14470
										Adding VARTA order # and delivery note # into navigator
										VARTA
										4/10/19 - 4/10/19


VARTA is requesting that the Order # and Delivery Note # show on the existing order screen on the 
navigator web page. These two things should come to us on their EDI feeds.

looking at an inbound order after its imported via boomi and trying to find these 2 fields

deliv note = cust ref = custid
varta order# = ref3


										
_________________________________________________________________________________________________________
/*									ATP-14690
										Phone mix up / issue
										AERO
										4/10/19 - 4/10/19

steph huff wrong name on voicemail but correct greeting 'andrea'

when called in directory using STE instead of finding steph it finds
char steward

called support after verifying everything looks correct in evolve portal

dir was sorting by 'last name' 'starting with' _____
which is why STE only found char steward

changed the label/desc of message which was dir can look up by name
to say it looks up by last name

got directions from support for changing VM intro
call into VM hit 1 then 9 for additional opts
then 2 for forwarding
then 2 to listen to current into (this should be other persons name andrea)
after confirming the name is incorrect change to current name using 1




										
_________________________________________________________________________________________________________
/*									ATP-14699
										Please ensure all leads have access 
										to \\aeroshare03\departments\Fairfield\Checklists Lead checklist
										AERO
										4/11/19 - 4/11/19

My leads can not access the checklist.

Annika Davis
Heather Biel
Billie Jo Hollandsworth
Isabel Andrade
Terry Overbey
Alejandra Anguiano

just need to update their permissions

										
_________________________________________________________________________________________________________
/*									ATP-14701
										Navigator Frozen
										AERO
										4/11/19 - 4/11/19
Erins navigator completely frozen

can force end her session maybe?

open task manager click users and then dropd down for specific user select nav and end task

happened again today 4/12/19 #BSY

erin.jones@aerofulfillment.com

#BSY 4/12 new nav issue - not related to erin
Connection name: SQL Data Source 2
Error message:
The schema does not contain the specified table: "Orders_IncidentLog".
Unable to load data into one or several datasources. See information above for details.	

_________________________________________________________________________________________________________
/*									ATP-14666
										shipping printers wont print cci canada customs invoice or navigator master
										packing
										AERO
										4/11/19 - 4/11/19
could be user related. said to try with herself logging in or someone else and see what
happens.

										
_________________________________________________________________________________________________________
/*									ATP-14627
										Abby cannot see images on the image approvals page.
										CPG
										4/11/19 - 4/11/19

CPG dotty sent email with image

verifying that when i log in i see only one image and abby sees 5?

none of which look to be in the folder in the path the link points to from
inspecting.

so quite possibly the images arent making it to that folder for some reason?
or the upload tool to that loc isnt working. or because the content folder is too full?
so they cant upload?

hoping cleaning up E: drive will allow change to test with
										
[pr_Process_ApproveImage]
[dbo].[pr_Process_DeclineImage]
[dbo].[pr_Process_NewImage]
Inventory_Image_Approval table
\\aeroshare03\Departments\IMAGES-NEW 2016\CPG\

so someone drops image into this folder and then itll be viewed for approval

theres also a boomi job for image approvals
C:\utils\ImageApproval\ImageApprovalConsole.exe

app and boomi move image from aeroshare03 to afsweb204.
afsweb204 was full so it didnt have room for image
now that theres space the image shows up

had to figure out what the image approvals jobs are doing. its 
connected to afsweb204, aeroshare03 and stored procs and a boomi job. 
ops drops sku into cpg folder in aeroshare03 with filename as sku/primary_ref 
and as a .jpg. boomi job picks it up and processes and moves to afsweb204. 
then it sits to be approved or rejected via abby on Image approval page 
and whichever choice fires off admin scripts which have stored procs in them as well

force updated existing stuck approval to 7.

-- update ii
	set [status] = 7,
		status_notes = 'Force rejecting - Image file lost'
--select * 
from mason.dbo.Inventory_Image_Approval ii
where ii.item_id = '417359'
and image_filename = '417359.jpg'
and image_id = '0838FD84-DB41-487C-8017-CD16BB0A4DF4'
order by add_date desc

_________________________________________________________________________________________________________
/*									CI-286
										create test plan for erin for allotment manager
										PGOC
										4/11/19 - 4/11/19
create test plan
james made manual guide

from SOW
TESTING AND ROLLOUT
 All Navigator testing will be conducted in Aero’s UAT environment.  
P&G Professional Oral Health– Aero Navigator Allocation Manager

and also atp-?

#allotment dev


submitimport

checkallotment
createnewallotment
add item
c is hard coded string line 913

can add ID to grid on exportallotment_click
allotmentexport.writecsvtoresponse
allotmentexport line 1090 allotman

--Grid_HtmlRowPrepared
 Dim customer As String = e.GetValue("MemberID").ToString()
            Dim customerType As String = e.GetValue("MemberType").ToString()




5/28 - 5/29 
spot to add column and change name is prot sub Grid_HtmlRowPrepared 953

change cust to custId
add dim for custType or member type
does this connect directly to a table? do i update table with another column?

#allotment
5/31
committed changes
of adding a dim of custtype to grid_htmlrowprepared also changed string name of customer to memberID
and updating the excel file to have another row as customer type
added grid.getdatarow item 7 and removed hard coded type of c

testing locally looks like i didnt truly find where the export will add or display the ID in excel

PWR1012	Role	458	10	5/31/2019	5/31/2020	1	A

#allotment
6/3
still need to change allotmentGrid for AllotmentExport
add the memberID to show whos name is whos ID
also may need to change to show the name as the team name or role name

rebuild after changing a function or private sub
-- may need to stop local iis efulfill app pool then start it again after rebuild

use breakpoints on the private sub with function in it
stepover pieces of private sub
step into function of check or createallotment
there you can see values given while testing import
order needed to be fixed of columns imported

have to make sure the id import can handle multiple ids
can creating a role allotment or using role id then allow use of 
transferring between ppl with that role


6/12
fix import? to make sure import role type creates customer allotments

fix link

fix error red to appear in a legend
-- currently in a control container of devexpress

sample of what to recreate
Protected Sub SaveAllotment_Click(sender As Object, e As EventArgs)
        allotmentGrid.Visible = True
        legend.Visible = True
        Cancel.Visible = False
        CreateAllotment.Visible = True
        newAllotmentForm.Visible = False
        SaveAllotment.Visible = False
        Transfer.Visible = True
        ImportAllotment.Visible = True
        ExportAllotment.Visible = True
        If newType.Text = "Customer" Then
            If Not (checkAllotment(SKUdropdown.Value.ToString, newCustomer.Value.ToString, newStartDate.Value.ToString, newEndDate.Value.ToString)) Then
                CreateNewAllotment(newCustomer.Value.ToString, newType.Value.ToString, newallotted.Value.ToString, SKUdropdown.Value.ToString, newStartDate.Value.ToString, newEndDate.Value.ToString, resetvalue.Value, resetInterval.Value)
            Else
                allotmentError.InnerText = "There is an allotment already."
                allotmentError.Visible = True
            End If
        ElseIf newType.Text = "Role" Then
            If Not (checkAllotment(SKUdropdown.Value.ToString, newMember.Value.ToString, newStartDate.Value.ToString, newEndDate.Value.ToString)) Then
                CreateNewAllotment(newMember.Value.ToString, newType.Value.ToString, newallotted.Value.ToString, SKUdropdown.Value.ToString, newStartDate.Value.ToString, newEndDate.Value.ToString, resetvalue.Value, resetInterval.Value)
                CreateNewAllotmentxRole(newMember.Value.ToString, "CR", newallotted.Value.ToString, SKUdropdown.Value.ToString, newStartDate.Value.ToString, newEndDate.Value.ToString, resetvalue.Value, resetInterval.Value)
            Else
                allotmentError.InnerText = "There is an allotment already."
                allotmentError.Visible = True
            End If
        Else
            If Not (checkAllotment(SKUdropdown.Value.ToString, newMember.Value.ToString, newStartDate.Value.ToString, newEndDate.Value.ToString)) Then
                CreateNewAllotment(newMember.Value.ToString, newType.Value.ToString, newallotted.Value.ToString, SKUdropdown.Value.ToString, newStartDate.Value.ToString, newEndDate.Value.ToString, resetvalue.Value, resetInterval.Value)
            Else
                allotmentError.InnerText = "There is an allotment already."
                allotmentError.Visible = True
            End If
        End If
        allotmentGrid.DataSource = getAllotment(SKUdropdown.Value.ToString)
        allotmentGrid.DataBind()

    End Sub

protected Sub submitImport_Click(sender As Object, e As EventArgs)
    Grid.DataSource = Session("ImportGrid")
    Grid.DataBind()
    Dim SKU As String
    Dim rowcount As Integer = Grid.VisibleRowCount
    Dim count As Integer = 0
    While count < rowcount
        SKU = getItem_id(Grid.GetDataRow(count).Item(0).ToString)
            If Not (checkAllotment(SKU, Grid.GetDataRow(count).Item(2), Grid.GetDataRow(count).Item(4), Grid.GetDataRow(count).Item(5))) Then
                If Grid.GetDataRow(count).Item(2) = "c" Then
                    CreateNewAllotment(Grid.GetDataRow(count).Item(1), Grid.GetDataRow(count).Item(2), SKU, Grid.GetDataRow(count).Item(3), Grid.GetDataRow(count).Item(4), Grid.GetDataRow(count).Item(5), Grid.GetDataRow(count).Item(6), Grid.GetDataRow(count).Item(7))
                ElseIf Grid.GetDataRow(count).Item(2) = "r" Then
                    CreateNewAllotment(Grid.GetDataRow(count).Item(1), Grid.GetDataRow(count).Item(2), SKU, Grid.GetDataRow(count).Item(3), Grid.GetDataRow(count).Item(4), Grid.GetDataRow(count).Item(5), Grid.GetDataRow(count).Item(6), Grid.GetDataRow(count).Item(7))
                    CreateNewAllotmentxRole(Grid.GetDataRow(count).Item(1), Grid.GetDataRow(count).Item(2), SKU, Grid.GetDataRow(count).Item(3), Grid.GetDataRow(count).Item(4), Grid.GetDataRow(count).Item(5), Grid.GetDataRow(count).Item(6), Grid.GetDataRow(count).Item(7))
                Else
                    CreateNewAllotment(Grid.GetDataRow(count).Item(1), Grid.GetDataRow(count).Item(2), SKU, Grid.GetDataRow(count).Item(3), Grid.GetDataRow(count).Item(4), Grid.GetDataRow(count).Item(5), Grid.GetDataRow(count).Item(6), Grid.GetDataRow(count).Item(7))
                End If
            Else
                allotmentError.InnerText = "There is an allotment already."
                allotmentError.Visible = True
            End If
            count = count + 1	
    End While
End Sub

cannot call the same function inside the calling of that function. can however keep using
the grid.GetDataRow that was inside function parameters outside since it is a diff fn


										
_________________________________________________________________________________________________________
/*									ATP-14673
										E drive full on AFSWEB204 - FW:Incident
										AERO
										4/11/19 - 4/11/19

zipping files from 
nav 
content (E:)\content\Navigator\export\
zip several dates and months

just deleted anything older than 90days from exports folder
now exports is only about 10GB and theres
22GB free which will go fast until we start a cleanup process for this

#BSY 4/15/19 still need feedback from josh on what i can use to help make a cleanup job

										
_________________________________________________________________________________________________________

												WEEK OF 4/15
												GOALS AND EXPECTATIONS
#BSY goals 

continue from last week
-- SPRINT 
--- Migrate from SFTP to AFSMTF02
---- create a plan of action about how we are going to accomplish this. needs to see movement on this
---- ticket as its been sitting 3 other weeks now

--- wella school program backups created
---- just create the backups from ssh and then close?

--- remove 660 zone that are "conveyable"
---- follow up with josh or archana?

--- asset management 
---- finish powerpoint using specific notes from chris and go over rest of plan before fri

--- estore and ecomm
---- finish changes from chris' notes that i dont currently have.
---- possibly start new ones if they are approved and billable.

this week
-- ticket cleanup
--- if we dont clean up lots of open tickets we work on saturday


_________________________________________________________________________________________________________
/*									ATP-14730
										Amy Pryce needs email access
										AERO
										4/15/19 - 4/15/19
set up an email acc in microsoft 365 admin portal and didnt notice til afterwards
but there is an Amy Price already made. Not sure who made it and when.


_________________________________________________________________________________________________________
/*									ATP-14738
										PEP bid for microsite
										AERO - PEP
										4/15/19 - 4/15/19

PEP wants a microsite up by 7/1/19 - we may est today at meeting


_________________________________________________________________________________________________________
/*									ATP-14673
										disk E: drive critical space - failed - less than 1gb of space
										AERO
										4/9/19 - 4/15/19
#BSY #drive

cleaned out by deleting exports contents older than 90 days but still using tons of room
need cleaup process for this. similar to issue with image uploads for image approval for CPG

josh says to use robocopy path/command
probably need to dl it
Joshes example -
this is prog/script
C:\Windows\System32\Robocopy.exe

this is arguments
C:\dx\Infor\ c:\dx\_archive\ *.xml /MIR /MOVE /MINAGE:30

can be weekly on sun maybe around 3 am?

his example is from afsinfor01 and 02.
dx archive

_________________________________________________________________________________________________________
/*									ATP-14695
										Remove 660 zone from "conveyable" zones across entire system
										AERO
										4/15/19 - 4/15/19

on new #sprint

notes from ticket Remove 660 from conveyable zones in the following.

Reports (including replenishment reports)
Auto Dock Confirmation process
Champ case id upload process
Basically search all stored procs for hard coded zones and remove 660



_________________________________________________________________________________________________________
/*									ATD-21
										Boomi process monitoring
										AERO
										4/15/19 - 4/15/19
possible real issues non ftp related?
-- DF magento ship confirms
-- CHAMP carton update
-- SA Quest pin master
-- atomsphere metadata download
-- subinfor response logs
-- PEP inv bal
-- AERO OrderPrintService ZEBRA140L14 ?

-- LUX_Retail Order Import - its luxs url thats having issue



_________________________________________________________________________________________________________
/*									ATP-14734
										Missing orders
										NARS
										4/15/19 - 4/15/19


select *
from Orders (nolock)
where fulfillment_id = 855
and customer_reference like '%NUS01031372%'
order by add_date desc

not in nav

need to be imported. failed to import - was during system incident josh mentioned last thurs evening


_________________________________________________________________________________________________________
/*									ATP-14736
										Order status files missing
										NARS
										4/15/19 - 4/15/19

james said he missed this on his morning rounds of checking for processes still running 

caused the rest of the scheduled processes for nar_ship_confirm to fail due to already
in progress over fri and sat- doesnt run on sunday.


_________________________________________________________________________________________________________
/*									ATP-14747
										give drew dunavent ability to place tickets
										OPS
										4/15/19 - 4/15/19
under ATP click customers then top right click add customers. 
add persons email here and hit ok


_________________________________________________________________________________________________________
/*									ATP-14746
										location update tool frozen
										OPS
										4/15/19 - 4/15/19
Mike Z
can you try cancelling this import, logging out and back in, and then retrying? 
Infor had to restart the excelt import service last time we had an issue like this so it could 
just be a simple refresh needed and giving infor time to clear that queue

from infor:Ben, 
You just need access to the app server. From there you can open the admin console and 
simply click on the Excel Import Server and stop then start it. That is all you need to do 
and it causes no down time for the operation.

asking them if there is an automation to fix this or if its a bug to be addressed so we
dont have to keep doing this manual refresh/restart

_________________________________________________________________________________________________________
/*									ATP-14732
										GI not sent back for these orders
										3PL 
										4/15/19 - 4/15/19

sk-2 or sk-II is part of learning works and the boomi job they are under is 3PL
checking boomi process of 945 to see if these went out yet
sent back verification on first two LK0000010945-LK0000010946-

select *
from scprd.wmwhse1.vw_LTLOrders (nolock)
where ShipmentKey = '0000081004'
-- --0015205318 - incorrect orderkey
select *
from wms_PICKDETAIL
where ORDERKEY = '0015261516'
and sku in ('82472769', '82473835')

#BSY 4/16 - 4/17 - opened infor ticket to see why this is not displaying some data and other is mismatched
LK0000011048 - this one has mismatching data and missing data in infor

ticket with infor invalid. 2 dif ship methods but non ltl (LK0000010935 was ltl)holding up last order due to
missing drop ids
doing manual update and then retransmit

-- update p
	set dropid = '00048328'
-- select *
from scprd.wmwhse1.pickdetail p
where orderkey = '0015205318'
and dropid <> '00048328'

once updated the 3pl_shipconfirm_ltl proc auto caught the update and then transmitted this last order



_________________________________________________________________________________________________________
/*									ATP-14748
										please attach sheet - vayyar order needs updated serials
										VAY 
										4/16/19 - 4/16/19
data for this update in excel doc vay sheet updated ben
primary ref = VA0000076366
--1
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1148' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961915'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0816' where LOTXIDLINENUMBER = '00002' and caseid = '0071961915'	
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4079' where LOTXIDLINENUMBER = '00003' and caseid = '0071961915'	
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1037' where LOTXIDLINENUMBER = '00004' and caseid = '0071961915'	
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1025' where LOTXIDLINENUMBER = '00005' and caseid = '0071961915'	
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0826' where LOTXIDLINENUMBER = '00006' and caseid = '0071961915'	
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3792' where LOTXIDLINENUMBER = '00007' and caseid = '0071961915'	
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2101' where LOTXIDLINENUMBER = '00008' and caseid = '0071961915'	
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1039' where LOTXIDLINENUMBER = '00009' and caseid = '0071961915'	
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3737' where LOTXIDLINENUMBER = '00010' and caseid = '0071961915'
--2
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2953' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961914'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0312' where LOTXIDLINENUMBER = '00002' and caseid = '0071961914'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1952' where LOTXIDLINENUMBER = '00003' and caseid = '0071961914'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0827' where LOTXIDLINENUMBER = '00004' and caseid = '0071961914'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3823' where LOTXIDLINENUMBER = '00005' and caseid = '0071961914'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4983' where LOTXIDLINENUMBER = '00006' and caseid = '0071961914'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2957' where LOTXIDLINENUMBER = '00007' and caseid = '0071961914'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1724' where LOTXIDLINENUMBER = '00008' and caseid = '0071961914'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1731' where LOTXIDLINENUMBER = '00009' and caseid = '0071961914'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1696' where LOTXIDLINENUMBER = '00010' and caseid = '0071961914'
--3
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2114' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961911'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1953' where LOTXIDLINENUMBER = '00002' and caseid = '0071961911'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3764' where LOTXIDLINENUMBER = '00003' and caseid = '0071961911'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2081' where LOTXIDLINENUMBER = '00004' and caseid = '0071961911'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1685' where LOTXIDLINENUMBER = '00005' and caseid = '0071961911'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3774' where LOTXIDLINENUMBER = '00006' and caseid = '0071961911'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2115' where LOTXIDLINENUMBER = '00007' and caseid = '0071961911'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1189' where LOTXIDLINENUMBER = '00008' and caseid = '0071961911'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3357' where LOTXIDLINENUMBER = '00009' and caseid = '0071961911'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2955' where LOTXIDLINENUMBER = '00010' and caseid = '0071961911'
--4
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1708' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961904'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1712' where LOTXIDLINENUMBER = '00002' and caseid = '0071961904'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2112' where LOTXIDLINENUMBER = '00003' and caseid = '0071961904'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1694' where LOTXIDLINENUMBER = '00004' and caseid = '0071961904'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1165' where LOTXIDLINENUMBER = '00005' and caseid = '0071961904'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1729' where LOTXIDLINENUMBER = '00006' and caseid = '0071961904'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2106' where LOTXIDLINENUMBER = '00007' and caseid = '0071961904'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1943' where LOTXIDLINENUMBER = '00008' and caseid = '0071961904'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1042' where LOTXIDLINENUMBER = '00009' and caseid = '0071961904'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1992' where LOTXIDLINENUMBER = '00010' and caseid = '0071961904'
--5
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2784' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961498'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0598' where LOTXIDLINENUMBER = '00002' and caseid = '0071961498'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2788' where LOTXIDLINENUMBER = '00003' and caseid = '0071961498'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4198' where LOTXIDLINENUMBER = '00004' and caseid = '0071961498'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3730' where LOTXIDLINENUMBER = '00005' and caseid = '0071961498'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2790' where LOTXIDLINENUMBER = '00006' and caseid = '0071961498'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0676' where LOTXIDLINENUMBER = '00007' and caseid = '0071961498'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0479' where LOTXIDLINENUMBER = '00008' and caseid = '0071961498'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2664' where LOTXIDLINENUMBER = '00009' and caseid = '0071961498'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2758' where LOTXIDLINENUMBER = '00010' and caseid = '0071961498'
--6
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1448' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961917'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4169' where LOTXIDLINENUMBER = '00002' and caseid = '0071961917'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2506' where LOTXIDLINENUMBER = '00003' and caseid = '0071961917'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2822' where LOTXIDLINENUMBER = '00004' and caseid = '0071961917'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4469' where LOTXIDLINENUMBER = '00005' and caseid = '0071961917'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0752' where LOTXIDLINENUMBER = '00006' and caseid = '0071961917'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3598' where LOTXIDLINENUMBER = '00007' and caseid = '0071961917'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2981' where LOTXIDLINENUMBER = '00008' and caseid = '0071961917'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1461' where LOTXIDLINENUMBER = '00009' and caseid = '0071961917'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1455' where LOTXIDLINENUMBER = '00010' and caseid = '0071961917'
--7
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0516' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961919'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2399' where LOTXIDLINENUMBER = '00002' and caseid = '0071961919'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2753' where LOTXIDLINENUMBER = '00003' and caseid = '0071961919'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1437' where LOTXIDLINENUMBER = '00004' and caseid = '0071961919'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4194' where LOTXIDLINENUMBER = '00005' and caseid = '0071961919'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0977' where LOTXIDLINENUMBER = '00006' and caseid = '0071961919'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1440' where LOTXIDLINENUMBER = '00007' and caseid = '0071961919'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0746' where LOTXIDLINENUMBER = '00008' and caseid = '0071961919'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2821' where LOTXIDLINENUMBER = '00009' and caseid = '0071961919'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0526' where LOTXIDLINENUMBER = '00010' and caseid = '0071961919'
--8
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0323' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961918'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3806' where LOTXIDLINENUMBER = '00002' and caseid = '0071961918'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1190' where LOTXIDLINENUMBER = '00003' and caseid = '0071961918'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1040' where LOTXIDLINENUMBER = '00004' and caseid = '0071961918'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0329' where LOTXIDLINENUMBER = '00005' and caseid = '0071961918'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3824' where LOTXIDLINENUMBER = '00006' and caseid = '0071961918'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3832' where LOTXIDLINENUMBER = '00007' and caseid = '0071961918'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2080' where LOTXIDLINENUMBER = '00008' and caseid = '0071961918'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1029' where LOTXIDLINENUMBER = '00009' and caseid = '0071961918'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3426' where LOTXIDLINENUMBER = '00010' and caseid = '0071961918'
--9
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0923' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961909'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0954' where LOTXIDLINENUMBER = '00002' and caseid = '0071961909'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4173' where LOTXIDLINENUMBER = '00003' and caseid = '0071961909'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1401' where LOTXIDLINENUMBER = '00004' and caseid = '0071961909'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2893' where LOTXIDLINENUMBER = '00005' and caseid = '0071961909'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0564' where LOTXIDLINENUMBER = '00006' and caseid = '0071961909'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2513' where LOTXIDLINENUMBER = '00007' and caseid = '0071961909'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4477' where LOTXIDLINENUMBER = '00008' and caseid = '0071961909'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2616' where LOTXIDLINENUMBER = '00009' and caseid = '0071961909'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0115' where LOTXIDLINENUMBER = '00010' and caseid = '0071961909'
--10
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1989' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961916'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1728' where LOTXIDLINENUMBER = '00002' and caseid = '0071961916'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1684' where LOTXIDLINENUMBER = '00003' and caseid = '0071961916'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1046' where LOTXIDLINENUMBER = '00004' and caseid = '0071961916'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0319' where LOTXIDLINENUMBER = '00005' and caseid = '0071961916'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2077' where LOTXIDLINENUMBER = '00006' and caseid = '0071961916'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4818' where LOTXIDLINENUMBER = '00007' and caseid = '0071961916'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3830' where LOTXIDLINENUMBER = '00008' and caseid = '0071961916'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1149' where LOTXIDLINENUMBER = '00009' and caseid = '0071961916'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1162' where LOTXIDLINENUMBER = '00010' and caseid = '0071961916'
--11
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2630' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961912'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2791' where LOTXIDLINENUMBER = '00002' and caseid = '0071961912'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1456' where LOTXIDLINENUMBER = '00003' and caseid = '0071961912'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4122' where LOTXIDLINENUMBER = '00004' and caseid = '0071961912'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0645' where LOTXIDLINENUMBER = '00005' and caseid = '0071961912'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1390' where LOTXIDLINENUMBER = '00006' and caseid = '0071961912'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4475' where LOTXIDLINENUMBER = '00007' and caseid = '0071961912'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2536' where LOTXIDLINENUMBER = '00008' and caseid = '0071961912'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0554' where LOTXIDLINENUMBER = '00009' and caseid = '0071961912'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0719' where LOTXIDLINENUMBER = '00010' and caseid = '0071961912'
--12
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3355' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961908'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1990' where LOTXIDLINENUMBER = '00002' and caseid = '0071961908'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4047' where LOTXIDLINENUMBER = '00003' and caseid = '0071961908'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3697' where LOTXIDLINENUMBER = '00004' and caseid = '0071961908'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1041' where LOTXIDLINENUMBER = '00005' and caseid = '0071961908'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3425' where LOTXIDLINENUMBER = '00006' and caseid = '0071961908'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2113' where LOTXIDLINENUMBER = '00007' and caseid = '0071961908'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1689' where LOTXIDLINENUMBER = '00008' and caseid = '0071961908'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0328' where LOTXIDLINENUMBER = '00009' and caseid = '0071961908'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0846' where LOTXIDLINENUMBER = '00010' and caseid = '0071961908'
--13
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2103' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961905'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1938' where LOTXIDLINENUMBER = '00002' and caseid = '0071961905'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3725' where LOTXIDLINENUMBER = '00003' and caseid = '0071961905'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0817' where LOTXIDLINENUMBER = '00004' and caseid = '0071961905'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1106' where LOTXIDLINENUMBER = '00005' and caseid = '0071961905'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2119' where LOTXIDLINENUMBER = '00006' and caseid = '0071961905'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0320' where LOTXIDLINENUMBER = '00007' and caseid = '0071961905'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1177' where LOTXIDLINENUMBER = '00008' and caseid = '0071961905'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3666' where LOTXIDLINENUMBER = '00009' and caseid = '0071961905'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3804' where LOTXIDLINENUMBER = '00010' and caseid = '0071961905'
--14
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0340' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961910'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1699' where LOTXIDLINENUMBER = '00002' and caseid = '0071961910'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0311' where LOTXIDLINENUMBER = '00003' and caseid = '0071961910'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0327' where LOTXIDLINENUMBER = '00004' and caseid = '0071961910'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0325' where LOTXIDLINENUMBER = '00005' and caseid = '0071961910'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4984' where LOTXIDLINENUMBER = '00006' and caseid = '0071961910'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1935' where LOTXIDLINENUMBER = '00007' and caseid = '0071961910'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3813' where LOTXIDLINENUMBER = '00008' and caseid = '0071961910'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1710' where LOTXIDLINENUMBER = '00009' and caseid = '0071961910'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0317' where LOTXIDLINENUMBER = '00010' and caseid = '0071961910'
--15
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3608' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961496'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2338' where LOTXIDLINENUMBER = '00002' and caseid = '0071961496'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4606' where LOTXIDLINENUMBER = '00003' and caseid = '0071961496'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0592' where LOTXIDLINENUMBER = '00004' and caseid = '0071961496'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0745' where LOTXIDLINENUMBER = '00005' and caseid = '0071961496'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0938' where LOTXIDLINENUMBER = '00006' and caseid = '0071961496'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4259' where LOTXIDLINENUMBER = '00007' and caseid = '0071961496'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2793' where LOTXIDLINENUMBER = '00008' and caseid = '0071961496'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1381' where LOTXIDLINENUMBER = '00009' and caseid = '0071961496'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4185' where LOTXIDLINENUMBER = '00010' and caseid = '0071961496'
--16
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2824' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961497'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4212' where LOTXIDLINENUMBER = '00002' and caseid = '0071961497'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2379' where LOTXIDLINENUMBER = '00003' and caseid = '0071961497'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0644' where LOTXIDLINENUMBER = '00004' and caseid = '0071961497'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2356' where LOTXIDLINENUMBER = '00005' and caseid = '0071961497'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0678' where LOTXIDLINENUMBER = '00006' and caseid = '0071961497'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1504' where LOTXIDLINENUMBER = '00007' and caseid = '0071961497'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2765' where LOTXIDLINENUMBER = '00008' and caseid = '0071961497'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2806' where LOTXIDLINENUMBER = '00009' and caseid = '0071961497'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4156' where LOTXIDLINENUMBER = '00010' and caseid = '0071961497'
--17
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2372' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961907'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3600' where LOTXIDLINENUMBER = '00002' and caseid = '0071961907'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2895' where LOTXIDLINENUMBER = '00003' and caseid = '0071961907'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0986' where LOTXIDLINENUMBER = '00004' and caseid = '0071961907'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0613' where LOTXIDLINENUMBER = '00005' and caseid = '0071961907'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2628' where LOTXIDLINENUMBER = '00006' and caseid = '0071961907'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0955' where LOTXIDLINENUMBER = '00007' and caseid = '0071961907'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2891' where LOTXIDLINENUMBER = '00008' and caseid = '0071961907'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0607' where LOTXIDLINENUMBER = '00009' and caseid = '0071961907'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3735' where LOTXIDLINENUMBER = '00010' and caseid = '0071961907'
--18
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4080' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961906'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3775' where LOTXIDLINENUMBER = '00002' and caseid = '0071961906'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1023' where LOTXIDLINENUMBER = '00003' and caseid = '0071961906'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2918' where LOTXIDLINENUMBER = '00004' and caseid = '0071961906'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3817' where LOTXIDLINENUMBER = '00005' and caseid = '0071961906'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1193' where LOTXIDLINENUMBER = '00006' and caseid = '0071961906'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3837' where LOTXIDLINENUMBER = '00007' and caseid = '0071961906'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1057' where LOTXIDLINENUMBER = '00008' and caseid = '0071961906'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0332' where LOTXIDLINENUMBER = '00009' and caseid = '0071961906'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1176' where LOTXIDLINENUMBER = '00010' and caseid = '0071961906'
--19
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1925' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961495'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S3800' where LOTXIDLINENUMBER = '00002' and caseid = '0071961495'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1489' where LOTXIDLINENUMBER = '00003' and caseid = '0071961495'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1726' where LOTXIDLINENUMBER = '00004' and caseid = '0071961495'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1945' where LOTXIDLINENUMBER = '00005' and caseid = '0071961495'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1667' where LOTXIDLINENUMBER = '00006' and caseid = '0071961495'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1941' where LOTXIDLINENUMBER = '00007' and caseid = '0071961495'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1032' where LOTXIDLINENUMBER = '00008' and caseid = '0071961495'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1713' where LOTXIDLINENUMBER = '00009' and caseid = '0071961495'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1174' where LOTXIDLINENUMBER = '00010' and caseid = '0071961495'
--20
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2757' where LOTXIDLINENUMBER = '00001' and CASEID = '0071961913'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2657' where LOTXIDLINENUMBER = '00002' and caseid = '0071961913'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0717' where LOTXIDLINENUMBER = '00003' and caseid = '0071961913'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S4181' where LOTXIDLINENUMBER = '00004' and caseid = '0071961913'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0594' where LOTXIDLINENUMBER = '00005' and caseid = '0071961913'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1516' where LOTXIDLINENUMBER = '00006' and caseid = '0071961913'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2468' where LOTXIDLINENUMBER = '00007' and caseid = '0071961913'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S0731' where LOTXIDLINENUMBER = '00008' and caseid = '0071961913'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S2639' where LOTXIDLINENUMBER = '00009' and caseid = '0071961913'
update wmwhse1.lotxiddetail set SERIALNUMBERLONG = 'WH1UCC0U838S1417' where LOTXIDLINENUMBER = '00010' and caseid = '0071961913'

-- remove old serials with this if they exist
delete scprd.wmwhse1.lotxiddetail where serialnumberlong like /*whatever the other format is in like *//*'%CN%' and sourcekey = '0015316605'
--select *
--from scprd.wmwhse1.lotxiddetail where serialnumberlong like '%CN%' and sourcekey = '0015316605'

change oother1 to current serialnumberlong

begin tran
-- update scprd.wmwhse1.lotxiddetail set oother1 = serialnumberlong where oother1 = '20190416999999' and sourcekey = '0015316605'
update scprd.wmwhse1.lotxiddetail set oother1 = serialnumberlong where oother1 = '20190416999999' and sourcekey = '0015316605'
select *
from scprd.wmwhse1.lotxiddetail where /*oother1 = '20190416999999' and*//* sourcekey = '0015316605'
rollback

above works so i can just do the update

_________________________________________________________________________________________________________
/*									ATP-14769
										OPS zero shipped a line on order#SL0000052453 and there was an issue
										and didnt zero ship. can you please ship in system
										SPL 
										4/17/19 - 4/17/19
OPs need to zero out open qty to zero ship this

--  #BSY 4/18/19 
didnt even give me time to respond this morning before they brought it up in daily planning meeting
they said they cant cuz its allocated 

told them they can unallocate themselves and then zero out open qty
_________________________________________________________________________________________________________
/*									ATP-14695
										Remove 660 zone from 'conveyable' zones across entire system
										AERO 
										4/17/19 - 4/17/19
Remove 660 from conveyable zones in the following.

Reports (including replenishment reports)
Auto Dock Confirmation process
Champ case id upload process
Basically search all stored procs for hard coded zones and remove 660
[wmwhse1].[pr_Process_AllocatedOrPicked]
release shipments - boomi job


auto dock confirm and champ proc dont seem to have 660 as a conveyable zone at all. 
going to check with dylan to see if he knows what reports are probably using this. anything 
else i should try to cover?

Ben Yurchison [5:04 PM]
just talked to dylan and this wasnt on ticket but apparently this ticket we are trying to 
solve the autodockconfirm issue for onnit before their large order hits monday. these zones 
in ticket were a theory of matts which is incorrect. so what next steps am i looking at to 
help get onnit orders to autodockconfirm?

#BSY 4/20/19

select *
from orders (nolock)
where fulfillment_id = 1163
and order_status <> 'SHIPPED'
order by add_date desc

-- possible good test orders
--ON0000001114
--ON0000046578 -- 39425285
--ON0000030043
--


select *
from wms_PICKDETAIL
where (loc like '660%'
or fromloc like '660%')
and ADDDATE > '03/01/2019'
and Storerkey = 'ONN'
order by ADDDATE desc

we rec order
waver goes to sc and creates shipment and then preprints /waves - manifest and dmsserver
then it goes to allocated
then pick
packed
shipped


select distinct wo.orderkey, wo.EXTERNORDERKEY
from DMSServer.dbo.shipments s (nolock)
join dmsserver.dbo.fa_shipment fs (nolock) on fs.suid = s.suid
join wms_orders wo on wo.externorderkey = s.SHIPPER_SHIPMENT_REFERENCE
join fulfillment f (nolock) on f.short_name = wo.storerkey
join wms_PICKDETAIL pd on pd.ORDERKEY= wo.ORDERKEY
left join enterprise.dbo.Fulfillment_Configurations c (nolock) on c.fulfillment_id = f.fulfillment_id
left join wms_transmitlog tl 
		on tl.key1 = wo.orderkey 
		and (		tl.tablename = 'autodockconfirm'
				or (tl.tablename = 'shipmentdockconfirm' and tl.transmitflag = 9)
				)
where --(s.SHIPMENTHOLD_FLAG = 1 or fs.ARO_DOCK_CONFIRM_FLAG = 1)
--and s.void_flag = 0
--and tl.serialkey is null
--and wo.[status] >= 55
--and (c.champ_packing_char is null or  (SUBSTRING(pd.fromloc,1,3) NOT IN ('610','620','625','630','635','640','642') and (select count ( * ) from wms_PICKDETAIL where SUBSTRING (fromloc,1,3)  IN ('610','620','625','630','635','640','642') and orderkey= wo.orderkey and status < 6) =0 ))
--and wo.EDITDATE > getdate() - 3
--and wo.storerkey = 'onn'
--and (fs.REQUEST_XML is not null and fs.REQUEST_XML not like '')
--group by wo.orderkey, wo.EXTERNORDERKEY
wo.EXTERNORDERKEY = 'ON0000030043'

select *
from dmsserver.dbo.shipments (nolock)
where SHIPPER_SHIPMENT_REFERENCE = 'ON0000046578'

checked above with james and verified they are working 


_________________________________________________________________________________________________________
/*									ATP-14771
										please take all access away from billie jo H
										AERO 
										4/17/19 - 4/17/19

#email
-- go into the person who is OOO or no longer with us and add a rule 
in the email section to give a new user access to read emails
can also configure to block login so original user cannot access
-- not sure if block overrides other users ability to see emails


_________________________________________________________________________________________________________
/*									ATP-14772
										dave cant print wave through case printing for KET wave
										KET 
										4/17/19 - 4/17/19
someone somewhere removed KET FP and BP documents from the fulfillment entirely
just had to add them back

_________________________________________________________________________________________________________
/*									ATP-14785
										mason supervisors special write access for folders
										KET 
										4/18/19 - 4/18/19
showed archana where to add these
S:\Mason Operations\PTO Calendar
S:\Mason Operations\Roster
S:\The Game Plan\Mason Game Plan\Transfer of Hours

_________________________________________________________________________________________________________
/*									ATP-14592
										Walmart UCC128 label setup
										VAY 
										4/17/19 - 4/17/19

need to make sure it gets updated SQL
to map WMIT - walmart item number
PO type - 4digit
and then almost everything else is the same 
5 digit dept #

have my own excel modeled after one josh used when mapping changes for PGOC

find code for o.consign case statements used in ras changes i was working on in nov

 case when o.consign like '%Nordstrom%' then right ('0'+convert(varchar, ff.flexfield17),4) 
		else convert(varchar, ff.flexfield17)end as 'Store',		
		-- case for nord add lead 0 for store else other stores no lead 0
should have full version saved in SQL file

 [dbo].[pr_Report_UCC_LTL_Labels]

 uses this proc above

 going to request them to use ff10,11,12,13
 for DC# POtype dept number and walmart prod #


_________________________________________________________________________________________________________
/*									ATP-14788
										Todd cant find discover files needed for job
										VAY 
										4/18/19 - 4/19/19

emails with todd
not sure if this was before the process of after 
but he says some process creates the the files and orders in infor and .txt files for him
using the file customer sends.
need to confirm with proof they sent while we look around on our end.

checking logs and boomi processes nothing failed that i can see
but need to look at logs for messages or errors maybe not displayed?
never seen this before but may be useful DX_StuckProcesses - view in mas


Event_Process_Log
EventLog
Fulfillment_Event_Log
pr_Web_Log_SelectALL
wms_LOGHISTORY
wms_TRANSMITLOG

#BSY 4/19/19
DS_VANTIV_2019041*   in boomi docs search
found job DS VANTIV and 2 others with affixes
didnt run on weds at all
im assuming because it wasnt sent to us
double checking

could have something to do with DS automemo - vantiv going back on 17th
with message of 
REASON                                                                                                                                               PTNYBOW
2PTB601100134792225SERRET/HQ-HQ DISCLOSURE LETTER RETURNED  USPS Return Code NR - NO 
going to check with Todd.

#BSY 4/20/19 or 4/22/19 
todd confirmed it was combined into the files for the 18th so it wasnt
made aware to him but sometimes happens

going to document everything i can about this process for others to be able to learn


_________________________________________________________________________________________________________
/*									ATP-14534
										incident: warehouse 3PL XML
										3pl 
										4/20/19 - 4/20/19
Hi, Team  We have detected the following failing message(s) for ZMATMD (OUTBOUND).   image001.png 
Error found in PI: RuntimeException during appliction Java mapping com/sap/xi/tf/
MM_ZMATMD_MATMAS03_Z1CMRA_To_TradeItemDocument_XsdGs1V202 
Thrown: com.sap.aii.mappingtool.tf7.IllegalInstanceException: Cannot create target 
element /ns0:tradeItemDocument/tradeItem/tradeItemInformation/tradingPartnerNeutralTradeItemInformation/
tradeItemMeasurements/depth/measurementValue/value. Values missing in queue context. Target XSD requires
a value for this element, but the target-field mapping does not create one. Check whether the XML 
instance is valid for the source XSD, and whether the target-field mapping fulfils the requirement of 
the target XSD   Cause of Error: Segment MEINH (path: /Z1CMRA/IDOC/E1MARAM/E1MARMM/MEINH) must be 
equal to "CS" for value to be created. Workaround/Fix: Kindly correct and resend.  
IDoc Number: 0000002339749532   Message ID: 3C4A92F624F51EE993DB40CF8DABC050  
error with the send of inventory possibly?

the root cause has been identified. This communication has been sent to 
notify affected users. Ticket routed to HPE_ITS_EAI_PIAS_L2.

sender component N6P420

#BSY 4/23/19 josh says this is part of 3pl boomi job?

inv status?
inv activity?
rec advice?
ship conf?


_________________________________________________________________________________________________________
/*												TICKET CLEANUP DAY
										moving several  tickets to dev or another project
										AERO 
										4/20/19 - 4/20/19

										
_________________________________________________________________________________________________________

												WEEK OF 4/22
												GOALS AND EXPECTATIONS
#BSY goals 
#estore - start developing devexpress changes and other items from phase 3 and finish phase2

#assetmgmt - follow up with matt/cdw on pricing plans bulk v monthly etc
		-- get more solid plan on laptops that IT can afford for ourselves
		-- find ideal docks as well

-- can convert key to ppt through export to tool
-- sent to chris 4/29/19

follow up on vayyar tickets

movement of ftp server - get with josh or james or filipe on questions as far as next steps
 -- 4/23/19 put all of ftp application IP whitelist back on peak10 firewall policy with BAE
 -- above

implement changes for help desk  - cant get behind

submit list to james for lunch and learn topics
priority:
Navigator/Magento development - basics of code changes - how to deploy dumbed down
SmartConnect - same as above
API tokens, connections, endpoints... - not much known by whole team besides james/lydia/josh
CHAMP/ Conveyor?

_________________________________________________________________________________________________________
/*									ATP-14817
										production label machine isnt working - printer SATO M-8400RVe
										AERO 
										4/22/19 - 4/22/19


this application requires a newer version of the microsoft .NET compact framework than the version
installed on this device

documentation for rf devices


_________________________________________________________________________________________________________
/*									ATP-14812
										ship station not working
										AERO 
										4/22/19 - 4/22/19
printer issues with network and multiple printers set up

solution:


_________________________________________________________________________________________________________
/*									ATP-14810
										please add navigator rf to 2 more RF guns
										AERO 
										4/22/19 - 4/22/19
lots of time on this. 



WH1UCC0U838S1486, WH1UCC0U838S2736, WH1UCC0U838S1369, WH1UCC0U838S4310,WH1UCC0U838S1996,
 WH1UCC0U838S4521,WH1UCC0U838S3256,
 WH1UCC0U838S4303, WH1UCC0U838S2737, WH1UCC0U838S0844


current unlicensed asset mgmt acc location

http://afsutil01:81/login.aspx


_________________________________________________________________________________________________________
/*									BAT PHONE
										deleted orders from wave may cause system down
										AERO 
										4/25/19 - 4/25/19
#BATCALL
issue 1
dave called
select *
from wms_WAVE (nolock)
where wavekey = 0000339231

select *
from wms_WAVEINPROCESS
where WaveKey = 0000339231

#BATCALL 
issue 2
atp-14862
dotty called 
status changes to CPG items
solvoyo updating our db incorrectly


#contacts energy
										
_________________________________________________________________________________________________________

												WEEK OF 4/29
												GOALS AND EXPECTATIONS
#BSY goals 

#estore
-- finish ticket for cpg research for solution for 1 site


also finish small changes for cpg

work on the catalog stuff


_________________________________________________________________________________________________________
/*									ATP-14928
										ESTORE MEETING
										CPG 
										4/30/19 - 4/30/19
2 hour meeting with david and abby at mason
notes are highlighted in #estore above
30m of travelling
cannot bill the fixing of import process not handling dupes


_________________________________________________________________________________________________________
/*									standup notes
										
										AERO 
										5/1
30m

ltlmanager = cls as far as rules go
these need to mirror rules and config for orders to be fully processed

_________________________________________________________________________________________________________
/*									ATP-14927
										ship station not working
										AERO 
										5/1/19 - 5/1/19
45m

blank shippers in shipper management

due to SimmShady

cls helped identify and then fix


_________________________________________________________________________________________________________
/*									TIT-2
										SOTI call with Josh and Fadil
										AERO 
										5/1/19 - 5/1/19

learned RF setup in SOTI software to at least get to where you get the exe that should be on every scanner
based on the RF model however.

could be a total of 10 or more dif exes needed based on all the models we have.

couldnt get exe to work though
1h

_________________________________________________________________________________________________________
/*									ATP-14937
										on site mason meeting with wendy from pgoc
										PGOC 
										5/2/19 - 5/2/19

the teams transferring within team
dont need cust to cust need team cust to team cust - james 
export and import tools working
search for allotments per sku advanced search based on name or w/e - ? est - out of scope
log management? - james - endless - uses pagination
import team and customers? - james - use template for allotment imports and click submit, import button not needed
csv - james - csv export just for reporting purposes - change wording
smaller sku list - ?
confirm reporting available - ?


rework of allot manager to include legend to detail
the differences between team and cust /cust of team allotment


_________________________________________________________________________________________________________
/*									ATP-14942
										PGOC allotment updates
										PGOC 
										5/2/19 - 
ticket for billable changes

_________________________________________________________________________________________________________
/*									CI-379
										PGOC bug fixes
										PGOC 
										5/2/19 - 5/2/19
ticket for nonbillable

_________________________________________________________________________________________________________
/*									ATP-14906
										billing storage report (new) rid 1424
										AOS 
										5/2/19 - 5/2/19


select *
FROM wms_SKUxLOC sl with (nolock)
		INNER JOIN wms_LOC l with (nolock)
			ON sl.loc = l.loc
		WHERE --sl.storerkey = @storerkey
			sl.sku = '670535116301'
			--AND sl.LOCATIONTYPE = @locationtype
			AND sl.qty > 0
			AND l.LOCATIONFLAG NOT IN ('DAMAGE','HOLD','PICKTO','INTRANSIT')
	ORDER BY sl.loc



_________________________________________________________________________________________________________
/*									ATP-13130
										add serial tracking to KET orders (archived)
										KET 
										5/3/19 - 5/3/19

none of what i did worked in scprd because its all archived.. wasted about 30m or more on that
but at least some of that goes towards remaking for scprdarc since i pushed for scprd.wmwhse2

still looks like many times running the proc where i have to change the serial and order number

must create ncounter next val proc in scprdarc and also catchdata_ket in scprdarc
^^^^ incorrect ^^^^^
above errored and from james explaining makes sense
the ncounter are unique keys
so passing them in arc and then prod merging or etc. will cause system failure or some break

so top of proc use scprd
then in selects into temp tables pull from arc and on insert only use prod

INSERT INTO wmwhse2.LOTXIDHEADER
SELECT * FROM #LH



_________________________________________________________________________________________________________
/*									ATP-1
										ESTORE MEETING
										CPG 
										5/7/19 - 5/7/19




										
_________________________________________________________________________________________________________

												WEEK OF 5/6
												GOALS AND EXPECTATIONS
#BSY goals 

#estore

#sftp migration

#vayyar #RF 2 barcode scanning

#asset management
finish getting all assets into budget amt 34k
laptops
docks
monitors
proj
joan




_________________________________________________________________________________________________________
/*									ATP-1
										nars inv summ report
										NAR 
										5/9/19 - 5/9/19
james said this is part of daily 8am
removed 4 users 
added 1

_________________________________________________________________________________________________________
/*									ATP-15024
										test
										aero 
										5/9/19 - 5/9/19
lupe test ticket

making sure hers arent duping anymore

_________________________________________________________________________________________________________
/*									ATP-15022
										missing order
										NAR 
										5/9/19 - 5/9/19


reran boomi job and verified order is in nav

james changed sunday schedule slightly to see if that helps


_________________________________________________________________________________________________________
/*									ATP-14832
										renee ken allotments
										coty 
										5/9/19 - 5/9/19

worked on this 2 weeks ago also 4/25

she followed up 4/29
need to finish 5/9 or 5/10



_________________________________________________________________________________________________________
/*									ATP-14151
										vayyar 2d barcode scanner set up
										VAY 
										5/9/19 - 5/9/19
spent time this week trying to set up new rf guns and also need to know exactly how we configure scanning for 2d barcode
shouldnt be hardware related?

possibly need to adjust 2d barcode config to use an extra char unless infor can handle a separator
or does it on its own.

but it should only be one serial per item per pick detail

#2d

need to make sure it parses
test in UAT
data flows where we want it to flow
2 check boxes
set delim
rf.Ini
these files in server help go from screen to screen


2 d barcode testing config to parse data
CSN:WH1UCC0U838S1726|CSN:WH1UCC0U838S1726
pipe after delim
will change to enter /carriage return



train users so when scanning they must hit fn after pick and
then scan 2d barcode i believe


whats going to need a label or not? business rule
lux? 
ltl vs small parcel?
will waiver know
cx person using switch?
labor to cost revenue
extra touch to put inside box


SM100
F2
SNBRCD10
Barcode must be associated with an item,whse, facility, and/or Vendor - please configure in WM
2nd error from facility level
com.agileitp.forte.framework.GenericException: java.lang.NullPointerException
excess serials scanned - please scan 0 serials
WMS0015456669
0015279591
WH21BBUS01

-- test order WMS0015519906
-- test 2 WMS0015536695 WMS0015536855

0015279593


0015279594


server afsinfor01 holds RF gun tasks for all wc-rf users

Mark.Schaible@infor.com

#2d barcode
5/30
on 5/28 marv sent new ini for Aero_Custom
this goes in the RF folder on each respective infor server path
C:\RF\handheld for prod

C:\rf\desktop for UAT

ALWAYS - make a backup of the current aero_custom.ini file and rename backup or old with a year maybe
 - copy new ini into folder
 - test

not sure the patches are the same and marv stated it wasnt in a version that can
test the 2d barcode. so i myself have to test in prod to see where the data goes
then be able to make test scenarios and train tomorrow

test 1
order with WH21BBUS01 only 

test 2
order with WH21BBUS01 but several picks

test 3 order with WH21BBUS01 and another sku (does this sku take serial or not? can try both ways)

scan case id normally
when prompted hit f2 then scan 2d barcode
1scan should get every EACH in that CASE or etc
as long as outbound capture data is turned on for that sku

follow up with marv sent email on 5/31
doesnt seem its going to barcode 2d menu properly when using f2



_________________________________________________________________________________________________________
/*									ATP-14972
										research effort to merge estore to ecomm to parent and etc for cpg
										CPG 
										5/9/19 - 5/9/19

PDP - pg pro
data entry
	-- tables and etc connected
	Data forms
		- DE install error log
			install error log search
			install tracking
			install tracking search
			points management
			point management search
			priorityshipping
			prio shipping search
			site survey update
			tsr training
			tsr training search
			tsr update

		- web promo
			search
			edit
		- fulfill acc cust lookup
		- allot man
			search
		- web suspended orders?	
	time to move to ESTORE - est 12 hrs
	 - adding in their allotment system with tables views, admin scripts, etc.
	 - fixing CSS to fit catalogs appropriately to also blend with other screens
	 - any extra logic implementations from order rules or admin script
	 - layouts/styles/JS

	admin scripts
		- allotment management aftersavedata
		- beforesavecustomer
		- several same as CPG
		- dataentry - 6 dif scripts
		- PDPstartcart
		- webselectproductload
		- webselectproductsubmit

ESTORE
catalogs - new catalogs - web mods tabs panels need to be updated to parent when merging
			- may need to update
	

select *
from ENTERPRISE.dbo.Web_fulfillment_settings (nolock)
where fulfillment_id in (73,521,724)
299 rows


CPG
-- webkit build

	time to move to estore?
		- turning off old catalog system replace with new catalog system - 3-5 h
		- changing tables, procs, boomi jobs to point to estore 521 as parent possibly with 73 and
			724 as children?
		- changing reports to use 521 as parent?
		boomi
		- prodorder notifications - 2h
		- quickbooks to work entirely through estore - 2h
		- TCD dropship setup - 5h
		- kroger 810 inv and 850 PO - 2h
		- intouch order export - SELECT * FROM vw_CPG_Intouch_Unconfirmed_Orders - still in use 2h
		- prod autowave retry -
	admin scripts
		- webkitbuildformload
		- webkitquickaddload
		- webkitquickaddsubmit
		- getkititems
		- webbatchCOEupdatesubmit
		- approveordermultiple
		- aftersubmitinventoryrequest
		- returnsmultientryload
		- fillformclick
		- emailreturns - adddetailsload, adddetailssubmit, afterload, load, submit, _deletereturn
		- login
		- approve order
		- cancel order
		- kitbuildload, kitbuildsubmit, kitbuildafterload
		- approveimage, cancel image, approveimageemail, declineimage email
		- aftersavewebrequest
		- top5suspendedprders, suspendeditems, suspendeditemscart
		- assignPO
		- reorderaddnewafterload, closereorders, reorderaddnewvalidatesubmit, reordereditsubmit,
			approvereordermultiple, reorderaddnewsubmit
		- vendorordereditsubmit



merge or add records to tables for CPG/PDP
for catalogs, Allotments



_________________________________________________________________________________________________________
/*									ATP-14980
										additional scope for estore
										cpg 
										5/9/19 - 5/9/19
est time to implement what abby and david are looking for

pitch them the new team feature and use the team feature to help lock down orders per user of team.
• set up/ config team feature for estore, testing and deployment 4h
then create a function to make sure appropriate team orders have approvals sent to team manager
• logic, testing deployment 4h

#infor account # 60029555
@dmin3900


_________________________________________________________________________________________________________
/*									mas daily planning
										mas 
										5/10/19 - 5/10/19
tickets
15031 
15032 pgoc
15033 cpg

15026 
ops fairfield op goals by client w/ filipe


#DOMAINCONTROLLER = aero-dc05



_________________________________________________________________________________________________________
/*									ATP-15035
										intl dialing access for angie and tami
										aero 
										5/10/19 - 5/10/19

verified they have access
provided instruction on how to dial to certain countries


_________________________________________________________________________________________________________
/*									ATP-15008 / 14923
										cant complete receipt for sku WAUSBCSHR02
										VAY 
										5/10/19 - 5/10/19

issue with rec trying to get receipt created for this item

WAUSBCSHR02

select *
from lebanon.dbo.inventoryedit (nolock)
where --item_status = 'active'
 primary_reference in ('WAUSBCSHR02','WH21BBUS01')

above shows results on both and look to be set up exactly the same (no mismatched fields)

going to check same in infor


select *
from lebanon.dbo.wms_RECEIPTDETAIL_All
where SKU = 'WAUSBCSHR02'

james said this is just user error to not use wh2

but found out today this is typo from CX who created sku in system

--update i
set primary_reference = 'WAUSBSCHR02'
--select *
from lebanon.dbo.inventory i(nolock)
where fulfillment_id = 1162
and primary_reference = 'WAUSBCSHR02'
and item_id = 402933
the C and the S were flipflopped
					
_________________________________________________________________________________________________________
					
_________________________________________________________________________________________________________

#log
#PRAGMA rf session manager etc
local server config
in afsinfor01 or uatinfor01 and so on

bullet points for erins concerns meet with her pre client meeting
PGOC ci-379
					
_________________________________________________________________________________________________________

34000002
#navigator #fix #reference #error
<add assembly="DevExpress.XtraCharts.v18.2.Web, Version=18.2.3.0, Culture=neutral, PublicKeyToken=B88D1754D700E49A" />
issue with web nav local


										
_________________________________________________________________________________________________________

												WEEK OF 5/13
												GOALS AND EXPECTATIONS
#BSY goals 

#estore 
-- tide test with traci

-- more changes pre dtr for items and etc.

-- est ticket with notes from abby
15048

-- #research
-- -- finish research of putting ecomm and estore and micro sites into one entity?

#asset management
-- wade may put something on calendar this week (im off friday)

-- make ppt look nicer?

#vayyar #2d 
-- finish 2d barcode config with infors help
-- scanners/RF guns still wont connect to afsinfor01?

pinging afsterm01 shows ip
192.168.22.108


#SFTP migration
-- sit down with filipe or josh for next steps

#cls fedex return shipping label

#coty 
-- super slow catalog page loading


_________________________________________________________________________________________________________
/*									ATP-15047
										create manifest for coty order
										COT 
										5/10/19 - 5/10/19

'CO0000001814 stuck Please create manifest record.'
matt wants manifest record created for this order

verified it doesnt already have manifest. 

used insert above under #manifest.


_________________________________________________________________________________________________________
/*									ATP-15041
										remove pdf from google search
										PGDERM 
										5/10/19 - 5/10/19
micro?FgQQYRES

pg derm aka pgsampling
part of servers
afsmweb1 and afsmweb2

root into through ssh (putty)
root login
BtjlwtXY afsmweb2
d1yKDaS afsmweb1

navigate to path shown in url that has pdf in this case:
https://pgdermatology.com/skin/frontend/pg-sampling/pg-sampling-theme/resouces/PHG-1107_Olay-Mailer_P1e-LowRes.pdf

use rm (remove) and then the path
and then do the same for other server

lastly if needed use google webmasters tools to request removal of old URL


_________________________________________________________________________________________________________
/*									ATP-15049
										FFDDR
										AERO
										5/13/19 - 5/13/19

fixed report job. afsreports.
the user trying to perform this file submission is crystal services
permission was wiped out last week from S drive issue.
added permission back to this user.


_________________________________________________________________________________________________________
/*									ATP-15056
										We need an ONNIT 2018 YE inventory report please provide, see attached
										ONN
										5/13/19 - 5/13/19

select *
from LEBANON.dbo.inventory (nolock)
where fulfillment_id = 1163


-- select * from enterprise.dbo.fulfillment (nolock)where short_name in ('ONN')
-- 1163

-- short_desc, long_desc, quantity
-- catalog, color, quality, damaged spoiled or expired, amount of liens against inv, receipts, size, and special markings or packing
-- detailed list of all trans posted to account for period dec 20, 2018 - jan 10, 2019
-- include item, qty and date activity of deliv or rec for each trans
-- statement of storage and other charges owed as of dec 31st, 2018

select *
from LEBANON.dbo.inventoryedit (nolock)
where fulfillment_id in (1163)

select *
from lebanon.dbo.inventory i (nolock)
join lebanon.dbo.inventoryedit e(nolock) on e.item_id = i.item_id and e.primary_reference = i.primary_reference
where i.fulfillment_id = 1163
and i.add_date < '2019-01-01 00:49:47.000'

going to refine so only pulling most relavant data then export to excel


_________________________________________________________________________________________________________
/*									ATP-14802
									Remove and reword 2 spots of diversey site
									DIVRSEY
									5/14/19 - 5/14/19

1. Update the email notification for Distributor approvals to be sent to Shera Smithson <shera.smithson@diversey.com>
2. Provide estimate for updating the current verbiage on New Account Registration Page (under account type) to state "Distributor accounts will be verified and approved within 2-3 days of W9 submission. Please submit to: na.distributor.programs@diversey.com
3. Provide an estimate for updating the text on the Thank you for registering page to state "Thank you for your registration. New accounts are subject to approval and once approved you will be notified via email. 
W9 submission to na.distributor.programs@diversey.com is required for account approval."

afsmicro1
root?
or stevebusam

pulled / cloned from github and opened in VS code

in module
	application
		src
			event listener
				registersuccesslistener.php

				found notification they want changed for item 3

incorrect repo as of 5/15 convo with matt wehrman

correct is diversey cbrebates
similar file structure

in module
	application
		service?
			mailer?
				mailer.php
				mailerservicefactory.php
				

in module
	application
		repository
			UserRepository.php
				has distributor role in it but unsure if this means theres the approve email also				
	
_________________________________________________________________________________________________________
/*									ATP-14768
									question from tracy
									RAS
									5/14/19 - 5/14/19

does field
shippingaccountnumber get mapped? can customer use for sending their fedex acc info

looks like this is mapped but not 100% sure where or if we store it in any field on order

	
_________________________________________________________________________________________________________
	
_________________________________________________________________________________________________________
					daily planning MASON
2 ket split shipments

FP open on split.

house included on tle sla?

15084 it request from an older ticket
15084 = ?
above match must not be labeled as PGOC
#query jira by company
type = 'Help Desk'  AND status != "done" AND status != "Waiting for customer" AND status != "Cancel" 
AND Company ~"P & G PROFESSIONAL ORAL CARE" ORDER BY created ASC

login through manager and through erin
walk through the process 

allotment manager
use template
import several customer allotments at a time as 'team'
manually have to do math on batch imports then transfers through manager do rest


muir.rt@pg.com
Bikram32

import support cust, role or team
based on type - requirements
import type
reference

adding role allotments in UI






_________________________________________________________________________________________________________

												WEEK OF 5/20
												GOALS AND EXPECTATIONS
#BSY goals 
	
#assetmgmt finish and present
-- update 5/21 make change to display our overall budget
-- make more of story to show cultural experience of getting updated equipment yearly and 4 year marks
-- 


_________________________________________________________________________________________________________
/*									ATP-14634
									time for a new computer? tracy e
									AERo
									5/21/19 - 5//19

need to use naming scheme and label. 

make sure to even rename take it off the domain first then re add it.
then continue setting up new image and make sure to download lsagent
also copy her stuff to cloud then pull down



#lansweeper
http://afsutil01:81/Default.aspx?tabid=1



_________________________________________________________________________________________________________
/*									ATP-15153
									please ship wave 0000334633 complete in system. all have tracking
									and are shipped
									PEP - pps
									5/21/19 - 5//19


tried to see why these arent making it to shipped status. looks like all caseids have
 valid manifest created.
 none void. cory thinks its an issue with ship pickdetail process

 
_________________________________________________________________________________________________________

_________________________________________________________________________________________________________


 go to aeroshare03 server
 right click my computer
 choose manage
 shared folders
 open files find path of file that was open



_________________________________________________________________________________________________________

_________________________________________________________________________________________________________


service 
overnight
next days hey shippers call cx
notify
service level vs zip validation

notification of change of service level

15031
15175

global find https comment out save rebuild
change directDA xml to point to UAT


_________________________________________________________________________________________________________

adding allotment man from pgoc to lux
using sql file insert for allotments
change to match lux

fit in 


_________________________________________________________________________________________________________

_________________________________________________________________________________________________________
 fairfield daily planning 5/25

 7 orders usb-c 

 master pack slip
 enable
 

 carrie
 user 5134593976@as.voip.fuse.net
 pw r1WLqm

 christy
user 5134593913@as.voip.fuse.net
pw 9FtC7A
184291redS

										
_________________________________________________________________________________________________________

												WEEK OF 5/28
												GOALS AND EXPECTATIONS
#BSY goals 

fix times in jira

#PGOC update allotment manager
-- need to make changes outlined by james and josh to fulfill Erin's request to be able to
more easily update and import the excel sheets with mass allotments in them

#sftp migration
-- need to start some of the converting work this week - due by EOW next week

#asset management 
-- follow up where possible. no wade today so likely no meeting between him and john this week
-- make sure laptops are viable options as replacements for us pros vs cons list

#pgboston
-- new site almost mirroring div days. 
-- im supposed to log 60h to this myself i believe
-- am i creating using magento? where to start

#sequence
-- deploy sequence change for old nav ticket - should be easy and small

#cory
-- cory will be leaving in 2 weeks.
-- find out whatever we can for him and try to have another lunch and learn.
-- try to log in confluence in lunch and learn section

#


										
_________________________________________________________________________________________________________

                                    NEW MSI LAPTOPS
_________________________________________________________________________________________________________

PROS                                        CONS
much bigger screen                          not usb-c chargeable
                                            much larger and bulkier to carry




_________________________________________________________________________________________________________
/*									ATP-15185
									user ids for receptionist like gloria is set up
									aero
									5/24/19 - 5/28/19
at first filipe showed how to create password and etc to have their login
for URL for receptionist software / service gloria uses

however he didnt test logging in as them and i did
it wasnt working due to no license
not able to configure as instructions show so called support and they set up
a license for carrie and christy
25/month so need to trim that later


_________________________________________________________________________________________________________

_________________________________________________________________________________________________________
 fairfield daily planning 5/25

dims continual issue

files sent to kelly

vayyar orders not getting through system
b2b orders missing notifications
large issue
no atp for orders, open ticket for notifications

VAR packing slip

VAR fedex login



_________________________________________________________________________________________________________
/*									ATP-15214
									barcode issues at ship station in shipping.
									aero
									5/29/19 - 5//19

looks like print head issue. can see scratches or worn down parts. this 
specific print head has no replacement from IT

probably need to overnight one


_________________________________________________________________________________________________________
/*									ATP-13979
									PG BOSTON build site like divdays is built
									PG
									5/29/19 - 5//19

building a new site for pg BOSTON
needs to be modeled like a microsite like divdays?

notes from SOW
similar to pg divdays and annual gift programs
web portal for emps to manage their reg info
as part of annual pg employee celebration
contain admin tools to enable aero cx team to manage changes of reg info
ability to import and export data

interact with IVR interactive voice response system where emps call and
provide their info. this info auto feeds to microsite
also include call center and mail processing services

3 domains related to scope
tech domain describes specific bis software apps
product domain describes specific types of prodcts
services domain describes specific and associated business processes

TD
    main page
        sign in with emp ID and home zip
        after sign in see current enrollment status
            cant request more than once
        
        allows user to validate following
            home addy
            max ticket count
            request more tickets
            require transportation y/n
            retiree y/n
            verify emp email addy
            select date. retirees only have one date
            confirm button that saves data
                •	Popup message: “By clicking submit,
                 you confirm all information on this page is accurate and ready to submit your ticket registration.”
                email conf
    admin
        top right corner link to main site
            users with admin allowed to acces management page
            manage page allows users to do following
                import users
                edit pg emp info
                export pg emp info
                set up two event dates and identify which retirees can attend
                ability to add delete update emp info
                ability to create a new admin user
                manage site assets
                    upload annual logo
                    change site colors
    reports
        scheduled report to be emailed to aero admins
            calls out any emp record that has been changed in which fields
                change in addy
                request for more tickets
                emp requires transportation status change
                retiree status change
                comment on emp record (who sees this?)
                emp email addy
        setup email box for emp to contact call center
    
    IVR
        set up feed from IVR to database

    vanity URL Gillettepicnic.com lev for microsite? pg will redirect url to aeros
    all emails sent to the employess should be sent (xxx)
 as users are familiar with it pg will provide aeros all information in order to send emails from that account

 use UAT environment to test

 provide 1800 number for customers to call with issues and request changes
    take calls to handle employee request to change/update registration data
    take calls to assist with employee questions on registration process
    hours 8am 5pm est m-f
    daily monitoring of email box

aero fulfill mailing services
    process initial mailing to retirees with info required for online redemption of the picnic tickets
        mailing qty of 3k letters single page 2sided
        aero to source #10 window envelope and inkjet return address
        letters to be mailed USPS first class mail presort

    will mail all the tickets to emp addy each will include
        # of tickets requested
        same number of food vouchers as tickets req
        one picture voucher
        aero to source #10 non window envelope and inkjet return address
        price assumes 561 active emp @ 5 tickets per and 687 retirees @ 2 tickets per

    Client exp
        manage site updates of txt and imgs
        site reporting import exp
        conduct weekly status calls


assumptions
    tech
        site will be turned off one week prior to first event
        site will be utilized year after year with txt and img updates from pg
        domain provided by pg
    products
        n/a
    services
        800 number acquired and utilized for future events
        approximately 3k retirees and 1300 emp


communication
    team members will report implementation progress and weekly status updates.
        important problems/actions taken
        progress summary
        accomplishments
        planned accomplishments
        issues log

approach for dealing with issues
    identify
    document
    assign responsibility for resolving
    monitor and control progress
    report progress on issue
    communicate issue resolution



takeaways
-- doesnt look to be much time alloted to ensure the IVR will communicate with db

actual exploration of divdays
takeaways
very small site
where are the connection strings to db?
    --


layout of divdays file structure

divdays folder
    divdays.sln
    App_Data
        publish profiles
            divdays.pubxml
    images
        logo_big.jpg
        logo_sm.gif
        Thumbs.db
    includes
        DivDays.inc
        DivDaysaddnew.inc 
        DivDaysaddnewcall.inc
        util.inc
        utiladdnew.inc
        utiladdnewcall.inc
    AddNew.asp
    AddNewcall.asp
    default.asp
    error.asp
    global.asp
    style.CSS
    Web.config
    website.publishproj


How do i create the webapp through visual studio to ensure it connects to our DB?
looks pretty straighforward

create new web app
-- make necessary matches to divdays
-- make callouts from SOW
    -- admin page for cx to control data
    -- initial registration
    -- signed in - verify and see status and how to use their info
    -- integrate IVR with db that has data flow
    -- call center
    -- emails and mailing


keepass has credentials for divdays
and other databases to see how its modeled to use for BOSTON

use strongly-typed views like ViewPage<ViewModel>
not ViewData["key"] or else you wont see misspelling errors

use an IoC container? to help manage all external dependencies

#pgboston 6/4
is the login page different page entirely from landing page?

admin has dropdown to select user name or id to update or add info for

DevExpress JS files and styles

@Html.DevExpress().GetStyleSheets(
        new StyleSheet { ExtensionSuite = ExtensionSuite.NavigationAndLayout },
        new StyleSheet { ExtensionSuite = ExtensionSuite.Editors }
    )
    @Html.DevExpress().GetScripts( 
        new Script { ExtensionSuite = ExtensionSuite.NavigationAndLayout },
        new Script { ExtensionSuite = ExtensionSuite.Editors }
    )


third-party JS files?

<resources>
        <add type="ThirdParty" />
    </resources>

do i need above for adding devexpress button or other items?


probably use controller for admin use
customer use
and possibly mail? probably need to use for service to auto mail out tickets?

need to create login page.

divdays uses .asp or language = vbscript to define global variables and constants
for addnew page?

divdaysaddnewcall.inc shows line 58 of sub ShowInformation(conn,rs,query,ID)
handles the display of existing divdays records

^ should try to replicate above to most closely match divdays if this can be accomplished easily
using c#


creating PGBOSTON database.. 
use right click of existing similar db
select script to then drop to and create to
immediately delete or comment out the drop database line **** DANGEROUS *****
make sure drives and names match up
for UAT vs prod the MSSQL\LOGS path is prod
UAT is MSSQL\LOG
switch up drive names
data drive is F: and logs drive is J: for UAT
data drive is E: and logs drive is L: for prod

"Views must be dumb (and Controllers skinny and Models fat). If you find yourself 
writing an “if”, then consider writing an HtmlHelper to hide the conditional statement."




_________________________________________________________________________________________________________
/*									ATP-15282
									Orders stuck in released status from 5/6 and 5/25
									ZEVO
									6/5/19 - 6/5/19

check boomi for documents for order numbers

1 needed address updated because it showed 5 st,,,,,

others failed from disk space issue
need to reset fulfill tran trans_status to 0

_________________________________________________________________________________________________________
/*									ATP-15283
									Please ship without manifest for vendor orders listed
									aero
									6/5/19 - 6/5/19

FI0000233304
FI0000232902
FI0000232277
FI0000233322
FI0000233851
FI0000233320

use cory's manifest script

_________________________________________________________________________________________________________
/*									ATP-15289
									scott kelly needs RF access like egner
									aero
									6/5/19 - 6/5/19

gave him the 4 or 5 permissions that egner has


_________________________________________________________________________________________________________
/*									ATP-15284
									imagen brands (discover)looking for alternatives to sftp
									for sending ship confirms of custom check presenters
									DFS
									6/6/19 - 6/6/19

call with kelly and discover FS
see what their process specifically is
see pain points then try to solve
-- likely dont have an automated process in place and want us to do manual effort instead

69.85.253.122

_________________________________________________________________________________________________________
/*									ATP-15286
									Following orders have an exceed error but i dont see anything
									exceeding RA48797 RA48784
									RAS
									6/6/19 - 6/6/19

not sure where to start but its stuck in allocated
event notes from joan at infor 

Event Log Notes: Ok...it should be corrected...please try to complete the pick.

Basically you check the data with the following queries. If there is a useractivity record still not at status 9, update that record to status 9 and then try to complete the pick. The user activity records are used for voice picking or assignment picking and are not needed when you are picking from other methods.

select * from pickdetail where orderkey='0015478124' and status<'5' order by orderlinenumber

select * from taskdetail where orderkey='0015478124' and status<'9' order by orderlinenumber

select * from USERACTIVITY where taskdetailkey in (select taskdetailkey from taskdetail where orderkey='0015478124') and status<'9'

statusmsg of user canceled/rejected

jennetta explained that as long as there arent records in useractivity should be fine to try and pick


_________________________________________________________________________________________________________
/*									ATP-15287
									AOS order stuck in packed status
									AOS
									6/6/19 - 6/6/19

stuck in packed
look at order lifecycle notification tables
indicates no manifest and was force shipped
use script to create fake manifest and then it should ship
#manifest

select *
from lebanon.dbo.orders o
where primary_reference = 'AS0000363832'

select *
from LEBANON.dbo.manifest (nolock)
where order_primary_reference = 'AS0000363832'

select *
from lebanon.dbo.Orders_ErrorCodes (nolock)
where errorCode = 34

select *
from lebanon.dbo.Orders_IncidentLog (nolock)
where orders_id = 39786532


____________________________________________________________________________________________

		aeroorders@aerofulfillment.com
		reset password through AD to admin pw of address
		cpgorders --- same thing
____________________________________________________________________________________________		



_________________________________________________________________________________________________________
/*									ATP-15292
									Vayyar 2 orders shipped but didnt send 856
									VAY
									6/6/19 - 6/6/19


select *
from lebanon.dbo.wms_orders wo
right join lebanon.dbo.orders o (nolock) on o.primary_reference = wo.EXTERNORDERKEY
where EXTERNORDERKEY in
(
'VA0000079815',
'VA0000079816'
)


trying to find logic in ltlmanager to why itd go to 5 status
and why dont we use 5 in 856 or other queries for GETs

from ltlmanager code
Private Sub Form1_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        'Version 2.0 (2/02/2008) uses LTLShipmentPallet table vs LTLShipmentDetail
        'Version 3.0 (3/14/2008) added new LTLShipment fields: storerkey, custom1, custom2.
        'Version 4.0 (5/15/2009) added support for both Mason and WC via entry in config file (Whse shows in Form title bar).
        '                        Re-coded all Crystal calls to be able to switch default login stored in the reports.
        '                        Added path to reports in the new config file. Default storer set to "PGOC" for Mason, "FW" for WC.
        '                        Consignee combo disabled for Mason. (consigneekey is only populated for F&W ASN customers)
        'Version 4.1 (7/20/2009) ShipFrom combo populated with AERO FULFILLMENT SERVICES, and then whatever Storer has been entered.
        'Version 4.2 (5/02/2012) Version to use with Infor 10.1 WMS upgrade and SCQA1 or SCPRD database. (compile with VS2008 due to Crystal) 
        'Version 4.3 (8/29/2012) Updated mainly for Mason, although applies to all. Fixed a few holes, added some checks for row.count>0.
        '
        '
        'DataSet List:
        'DataSet1 - LTLShipment, main form header data
        'DataSet2 - LTLShipmentPallet, datagrid item data
        'DataSet3 - LTLShipment, ShipmentKey combo data
        'DataSet4 - LTLShipment, used to retrieve last inserted key
        'DataSet5 - LTLShipment, pr_LTLAvailablePallets for Treeview
        'DataSet6 - LTLShipment, mbol for current pronumber
        'DataSet9 - Fulfillment, list of long names for Ship From.

        'EDIStatus
        ' 0 = Not Required
        ' 1 = Not Sent
        ' 5 = Ready
        ' 9 = Sent


then lines 2135 in Form1.vb in ltlmanager states

sent the ship confirm but estimating on new ticket the solution



_________________________________________________________________________________________________________
/*									ATP-15299
									yesterday conf file dumped and unable to apply them correct
									file and resubmit.
									ATK
									6/6/19 - 6//19

not sure what the issue is. nothing on ticket tells us and looking at files isnt obvious
per karen on client response there are gaps in some fields that are supposed to represent the date
the only thing that appears wrong is the ship address 1 having no address but a building or company name.

per client in email 
"There are blanks in the date field, this will cause a data decimal error due to an alpha character in a numeric field."

update -- looks like all the orders missing date were somehow effected by phone number?
every order without date created by the shipconfirm proc dont have valid phone numbers just
all show 0.



_________________________________________________________________________________________________________
/*									ATP-15309
									ship confirm running too slow
									SK2 / 3pl
									6/6/19 - 6//19

running 20 minutes for 0 data

looking through procs and boomi jobs to see what could be slowing it down so much. i dont think any
 of the procs have changed much recently but it has to be related to that or database? boomi jobs i 
 believe are 100% untouched since 2017 and this is a recent thing maybe


_________________________________________________________________________________________________________

_________________________________________________________________________________________________________

						FF daily planning
 Lsk 11884 - atp-15327
 also 15226

CMG dropid manual update

-- TK000140260 stuck?

crtl ? comments line?

atp-15287
5 or less we will fix. rest need to use fix manifest tool



_________________________________________________________________________________________________________
/*									ATP-15323
									ZO0000026172 this is stuck due to no drop id please create manifest
									Zevo
									6/10/19 - 6/10/19

https://secure.aerofulfillment.com/eFulfillment/help/Filling_in_Missing_DropIDs.pdf

OPS: PickDetail records are missing the dropID value, which links each caseID to the LTL shipment.


_________________________________________________________________________________________________________
/*									ATP-15321
									ship order lc%811707 in system	
									lux
									6/10/19 - 6/10/19
had lpn and loc messed up in pickdetail so it needed allocation fixed.
 used --update to pickdetail for loc = fromloc




---- 
-- notes from max could be port blocked from 20 or 21? 
-- 22 ssh

-- 80
-- 443

-- need to use JS or jquery to use a function where
-- using on_change()