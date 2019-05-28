/*                  AFI / AWI EOM process                           */
-- using these queries and tools to fix orders during validation


--investigating why ff5 and ff13 failed valid. due to len of code 
USE [LEBANON]
GO
/****** Object:  UserDefinedFunction [dbo].[AFICostCenter]    Script Date: 11/27/2018 9:36:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO








ALTER     FUNCTION [dbo].[AFICostCenter] 
(
	@normalcode varchar(19),
	@overridecode varchar(19)
)  
RETURNS varchar(10)
AS  
/*
	Armstrong Function():
	Return accounting CostCenter used in GL file from Account Code flexfield.

	Format: 
	ccccGGGGGxxxxxxxxx	(c=company, G=GLAcct, x=Int Order or Costcenter or ProfitCtr)
	CostCenter = 6-9 chars alpha/numeric (ends numeric)
*/
BEGIN
	DECLARE @accountcode varchar(19), @lgth int
	SET @accountcode = case 
		when isnull(@overridecode,'')='' then @normalcode else @overridecode end

	SET @lgth = len(@accountcode)

	RETURN case 
		when @lgth between 15 and 19 and isnumeric(substring(@accountcode,@lgth,1))=1 
		then upper(substring(@accountcode,10,@lgth-9))
		else '' end

END

-- queries for finding and then fixing

select *
from lebanon.dbo.orders (nolock)
where orders_id in (
37650513,
37684455,
37705520)

select *
from lebanon.dbo.orders (nolock)
where orders_id in (
37640303)

select *
from lebanon.dbo.inventory_flexfields (nolock)
where item_id in ('324686',
'339571')
-- order_primary_reference in ('FI0000191262', 'FI0000192206', 'FI0000192947')


select *
from lebanon.dbo.lineitemsearch (nolock)
where orders_id in (37640303)

select (dbo.AFICostCenter('C551175054637',''))
select (dbo.AFIInternalOrder('C551175054637',''))
AFIProfitCenter
select (dbo.AFIProfitCenter('C551175054637',''))
select len('C551175054637')

-- update for to make fix

--update l
set flexfield1 = 'C5511722040173', flexfield2 = 'C55125101FGNBSCTRL', flexfield3 = 'C5511722040173', flexfield4 = 'C5511722040173'
--select *
from lineitemsearch l(nolock)
where orders_id in (37650513,37684455,
37705520)
 and lineitem_id in (222308466,
222372067,
222419295)
and fulfillment_id = (select fulfillment_id from Fulfillment where short_name = 'AFI') and
[add_date] > convert(datetime,convert(varchar,getdate()-35,101)) and
isnull(flexfield13,'')<>'' and 
isnull(vendor_status,'')='' and qty_shipped>0 and
line_status = 'SHIPPED' and inventory@primary_reference<>'99999' --and (left(isnull(flexfield13,''),4)



/* run all validation
 then run first execution 
--	EXEC [dx_AWI_CreateReceivables] @mode = 'NEW'
 and following 2 or 3 queries

 afterwards run tax export calc in boomi afsatom 01 
 once finished run tax export send in afsatom 02

\\afsatom02\DX\AWI
 then run tax import afsatom01 and run following queries

 next run dx create data execution called [dx_AFI_CreateGLData] 
 follow this with 2 little queries then serious code check query
SELECT * FROM AFI_GLHeader
WHERE add_date > getdate()-5 does this need results?

 once all these are completed we run the master ar/gl process in boomi
 find the email sent in boomi and download and change file type to ZIP
 next run the AR send in afsatom02 
 once ar send is done run GL send afsatom02 

 after these are all completed send the zip to kelly
 and then send confirmation of completion to kelly and contact at awi or afi
 ex:

 subject:AWI EOM 9/25/18
  and doc to kelly

ex:
to:DATrimble@armstrongceilings.com for AWI OR for AFI 'mmoralespagan@armstrongflooring.com' and kelly'mmoralespagan@armstrongflooring.com'
subject: 2018-09-25 Ceiling EoM

body: 
The EoM files have been submitted for AWI.

Thanks,
*/

-- how james helped validate that AR_awp didnt have data to send or create
-- for file. meaning nothing was flagged for invoicing for div/ cost center awp
select *
FROM Orders o with (nolock)
    INNER JOIN Orders_Flexfields ox with (nolock)
        ON o.orders_id = ox.orders_id
    INNER JOIN Lineitem l with (nolock)
        ON o.orders_id = l.orders_id
    INNER JOIN Lineitem_Flexfields lx with (nolock)
        ON l.lineitem_id = lx.lineitem_id
    INNER JOIN Inventory_Flexfields ix with (nolock)
        ON l.item_id = ix.item_id
    INNER JOIN Customer btc with (nolock)
        ON ox.fulfillment_id = btc.fulfillment_id
        and ox.flexfield14 = btc.primary_reference
    INNER JOIN Customer_Flexfields btcx with (nolock)
        ON btc.customer_id = btcx.customer_id
        and btc.fulfillment_id = btcx.fulfillment_id
    INNER JOIN Customer_Address bta with (nolock)    --joins on all BillTo address types
        ON btc.customer_id = bta.customer_id
        and btc.fulfillment_id = bta.fulfillment_id
    INNER JOIN
        (SELECT customer_id,
                woodcnt = sum(case address_type when 'BT-C086' then 1 else 0 end)
            FROM Customer_Address with (nolock)
            WHERE fulfillment_id = (select fulfillment_id from fulfillment where short_name = 'AFI')
            and address_type like 'BT%'
            GROUP BY customer_id) cwd
        ON btc.customer_id = cwd.customer_id    
    WHERE --line is shipped, we have an income account
        o.fulfillment_id = (select fulfillment_id from Fulfillment where short_name = 'AFI')
        and o.order_type in ('STANDARD','BACKORDER')
        and isnull(ox.flexfield2,'0') = '1'            --Invoice customer flag
        and o.order_status = 'SHIPPED'        --3/18/2011 added for vendor orders
        and l.line_status = 'SHIPPED'
        and l.qty_shipped > 0
        and isnull(l.vendor_status,'')=''    --12/15/2011 not a dropship line
        and o.billing_date >  '2018-11-01'
        and o.billing_date <= '2018-11-26'
        and bta.address_type like 'BT%'
        and (
            --check for Wood BillTo with Wood Item
            (bta.address_type='BT-C086' and left(isnull(ix.flexfield9,''),1)='3')
            --we have a Wood BillTo, but this is for a non-Wood BillTo and non-Wood item
            or (cwd.woodcnt>0 and bta.address_type<>'BT-C086' and left(isnull(ix.flexfield9,''),1)<>'3')
            --or, no separate BillTo for Wood
            or cwd.woodcnt=0
            )
        and isnull(lx.flexfield1,'')<>''    --income code
        and isnull(lx.flexfield1,'')<>'XXXXX'    --8/28/2012
        and left(isnull(ix.flexfield9,''), 1) = '3'






        -- manually updating the dates for invoice for EOM

        USE LEBANON
GO

--Make sure today is the correct day to run the AR/GL Processes
--IF EXISTS (SELECT 1 FROM List_Value (nolock) WHERE List_Id = (select list_id from list where List_Name = 'FLOORING INVOICE DATES') and display_value=convert(varchar,getdate(),101)) --select * from list where fulfillment_id = 705
	SELECT DateCheck = 'YES!  TODAY IS AW EOM DAY!'
ELSE
	SELECT DateCheck = 'NO - NOT TODAY!!'


select * from lebanon.dbo.List_Value (nolock) where List_Id =
(select list_id from list (nolock) where List_Name = 'FLOORING INVOICE DATES')

IF EXISTS (SELECT 1 FROM List_Value (nolock) WHERE List_Id = (select list_id from list where List_Name = 'CEILING INVOICE DATES') and display_value=convert(varchar,getdate(),101)) --select * from list where fulfillment_id = 705
	SELECT DateCheck = 'YES!  TODAY IS AW EOM DAY!'
ELSE
	SELECT DateCheck = 'NO - NOT TODAY!!'


select * from lebanon.dbo.List_Value (nolock) where List_Id =
(select list_id from list (nolock) where List_Name = 'CEILING INVOICE DATES')

-- update List_Value
set Display_Value = '03/26/2019',
	Bound_Value = '03/26/2019'
	-- select * from List_Value
where List_Id = 669
and [Sequence] = 108
and Display_Value = '03/25/2019'


-- update List_Value
set Display_Value = '03/26/2019',
	Bound_Value = '03/26/2019'
	-- select * from List_Value
where List_Id = 687
and [Sequence] = 108
and Display_Value = '03/25/2019'



issue for 3/26 AFI only

had to dig through query for [dx_AFI_CreateGLData]
looking around for what is missing in the 3 items


-- having repeating issues with orders not having asset code and expense code on order or inv flexfields
-- changing the process in boomi to filter differently?

/*	AW A4 Create Monthly GL Data	*/
--dx_AFI_CreateGLData 'RESET'
--Then run these sanity checks..
--dx_afi_createGLData 'NEW'
SELECT * FROM AFI_GLHeader
WHERE add_date > getdate()-5
--
SELECT * FROM AFI_GLDetail
WHERE GLBatchName like '%' + (SELECT max(right(GLBatchName,4)) FROM AFI_GLHeader WHERE add_date > getdate()-5)
and GLBatchName = 'ZFVFPGL0319'
and TranType = 'IVAL'
ORDER BY 2

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

--Run this audit after GL is created (should not return any rows)...
SELECT * FROM AFI_GLCodeCheck (nolock)

select * 
from inventoryedit (nolock)
where item_id in (324830, 327940, 324834)


/* still issues with certs


also AFI procs dont seem to be pulling in INTL order data

[dbo].[pr_AFICodeRepair]

rerunning the create receivables. 

originally only pulled 11 records total for the month

SELECT flexfield2, l.* FROM dbo.OrdersEdit o 
INNER JOIN dbo.Lineitem l WITH (NOLOCK)
	ON l.orders_id = o.orders_id
WHERE o.fulfillment_id = 1093 AND o.billing_date > '2019-03-26'
AND isnull(o.flexfield2,'0') = '1'  
and isnull(l.vendor_status,'')='' 

need to verify what orders are what. dropship orders dont count and most of the taxables were dropship
besides 16 and thats not with all the filters

in AWI_GL_InventoryTransactions in dx_AWI_CreateGLData
the first select wasnt pulling correctly because the math was trying to div
by 0 for item BPCS5992
because it had a '' default_uom in inv which
was joined to pd.uom Inventory_PackDetail
where '' uom  = 0 units
updated to 'CS' and should work

need to write a case or if statement at beginning of AWI_GL_InventoryTransactions
to make sure nothing is set to 0 in units so there are no divide by 0 errors

or may need to change stored proc elsewhere to do more validation across the tables involved
so nothing has these '' (blank) values for UOM or 0 in units