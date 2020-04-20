USE Viewpoint
go

create PROCEDURE mspEnumPurchaseOrder
(

	@PO		bPO				=null
,	@McKPO	VARCHAR(30)		=null

)

AS

/*
2014.11.05 - LWO
	Utility Procedure that takes either the System PO Number (Requisition Number) or the McKinstry PO Number 
	and returns the entries in the appropriate Batch and transation tables.

	
	EXEC mspEnumPurchaseOrder
		@PO		=NULL			--'130100373'
	,	@McKPO	='14308009'		[Required to get results]
*/


SELECT 'POHB' AS TableName, 'Batch Header' AS TableDesc, Co, PO, udMCKPONumber, BatchId, * FROM POHB WHERE PO=@PO OR (udMCKPONumber=@McKPO AND @McKPO IS NOT NULL)
SELECT 'POIB' AS TableName, 'Batch Detail' AS TableDesc, Co, BatchId, * FROM POIB WHERE BatchId IN (SELECT DISTINCT BatchId from POHB WHERE PO=@PO OR (udMCKPONumber=@McKPO AND @McKPO IS NOT NULL) )  

SELECT 'POHD' AS TableName, 'PO Header' AS TableDesc, POCo, PO, udMCKPONumber,* FROM POHD WHERE PO=@PO OR (udMCKPONumber=@McKPO AND @McKPO IS NOT NULL)
SELECT 'POIT' AS TableName, 'PO Detail' AS TableDesc, POCo, PO ,*  FROM dbo.POIT WHERE CHECKSUM(POCo, PO) IN ( SELECT DISTINCT CHECKSUM(POCo, PO) FROM POHD WHERE PO=@PO OR (udMCKPONumber=@McKPO AND @McKPO IS NOT NULL) )

GO

EXEC mspEnumPurchaseOrder
	@PO		=null			--'130100373'
,	@McKPO	=null



SELECT 
	pohd.POCo
,	pohd.PO
,	pohd.udMCKPONumber
,	pohd.OrderedBy
,	pohd.OrderDate
,	pohd.JCCo
,	pohd.Job
,	poit.SMCo
,	poit.SMWorkOrder
,	smst.Type
FROM 
	POHD pohd join
	POIT poit ON
		pohd.POCo=poit.POCo
	AND pohd.PO=poit.PO JOIN
	HQCO hqco ON
		pohd.POCo=hqco.HQCo
	AND hqco.udTESTCo <> 'Y' LEFT OUTER JOIN
	dbo.SMWorkOrder smwo ON
		poit.SMCo=smwo.SMCo
	AND	poit.SMWorkOrder=smwo.SMWorkOrderID LEFT OUTER JOIN
	dbo.SMServiceSite smst ON 
		smwo.SMCo=smst.SMCo
	and smwo.ServiceSite=smst.ServiceSite
WHERE
	pohd.OrderDate >= '11/5/2014'	
AND poit.SMWorkOrder IS null

