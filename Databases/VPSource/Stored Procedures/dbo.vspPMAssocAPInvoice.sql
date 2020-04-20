SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************/
CREATE Proc [dbo].[vspPMAssocAPInvoice]
/*******************************
* Created By:	GF 11/02/2010 - issue #141957
* Modified By:	GF 06/22/2011 D-02339 use view not tables
*
* This stored procedure will be called from the APTL insert and update triggers
* to manage the relationships with the PM Tables. Data integrity exists to handle
* deleting records from APTL.
*
* We pass in a mode so that we can remove a relationship when the APTL update trigger
* is changing the PO/SL or the line type. This would then invalidate the relationship
* in PM. If the update trigger is changing the PO/SL, then we will fire this procedure
* again from the update trigger to insert the new relationship.
*
* Relationships in PM to update will be for PM ACOS AND PM PCOS.
* This will change as we add more.
*
* input paramters
* @APTLKeyID		APTL KeyID
* @Mode				'I'nsert or 'D'elete
*
*******************************/
(@APTLKeyID BIGINT = NULL, @Mode CHAR(1) = 'I', @OldLineType TINYINT = 0)
as
set nocount on

declare @rcode INT, @APCo INT, @PO VARCHAR(30), @SL VARCHAR(30),
		@LineType TINYINT, @POKeyID BIGINT, @SLKeyID BIGINT

SET @rcode = 0

---- must have APTL KeyID
IF @APTLKeyID IS NULL GOTO bspexit
---- need a mode
IF @Mode IS NULL SET @Mode = 'I'
---- if we are deleting old the old line type must be 6 0r 7
IF @Mode = 'D' AND @OldLineType NOT IN (6,7) GOTO bspexit


---- delete relationship if mode = 'D' then exit
---- the delete may happen if an APTL record was edited
---- via a batch and the line type was changed or the PO
---- was changed. This would force us to delete relationship
---- and then insert new relationship if needed from APTL update trigger.
---- if the @Mode is 'D' delete then do this first using keyid
IF @Mode = 'D'
	BEGIN
		---- record side
		DELETE dbo.PMRelateRecord WHERE RecTableName = 'APTL' AND RECID = @APTLKeyID
		---- link side
		DELETE dbo.PMRelateRecord WHERE LinkTableName = 'APTL' AND LINKID = @APTLKeyID
		GOTO bspexit
	END
	
	------ delete PO - line type = 6
	--IF @OldLineType = 6
	--	BEGIN
	--	---- record side
	--	DELETE dbo.vPMRelateRecord WHERE RecTableName = 'bAPTL' AND RECID = @APTLKeyID
	--	---- link side
	--	DELETE dbo.vPMRelateRecord WHERE LinkTableName = 'bAPTL' AND LINKID = @APTLKeyID
	--	GOTO bspexit
	--	END
	------ delete SL - line type = 7
	--IF @OldLineType = 7
	--	BEGIN
	--	DELETE dbo.vJNCT_APInvoice_SLSubcontract
	--	WHERE InvoiceID=@APTLKeyID
	--	---- record side
	--	DELETE dbo.vPMRelateRecord WHERE RecTableName = 'bAPTL' AND RECID = @APTLKeyID
	--	---- link side
	--	DELETE dbo.vPMRelateRecord WHERE LinkTableName = 'bAPTL' AND LINKID = @APTLKeyID
	--	GOTO bspexit
	--	END
	--END
	
	
---- get needed info from APTL to locate SL/PO
---- line type is 6-PO 7-SL
select @APCo=APCo, @PO=PO, @SL=SL, @LineType=LineType
from dbo.bAPTL WHERE KeyID=@APTLKeyID
if @@ROWCOUNT = 0 GOTO bspexit

---- check line type
IF @LineType NOT IN (6,7) GOTO bspexit

---- manage association for APTL to PO - line type = 6
IF @LineType = 6
	BEGIN
	---- GET PO KEY ID IF EXISTS
	SELECT @POKeyID=KeyID
	FROM dbo.bPOHD WHERE POCo=@APCo AND PO=@PO
	IF @@ROWCOUNT = 0 GOTO bspexit

	---- establish relationship if mode = 'I' and not already exists
	IF @Mode = 'I'
		BEGIN
		---- PO relationship
		INSERT dbo.PMRelateRecord (RecTableName,RECID,LinkTableName,LINKID)
		SELECT 'POHD', @POKeyID, 'APTL', @APTLKeyID
		WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord x WHERE x.RecTableName='POHD'
					AND x.RECID=@POKeyID AND x.LinkTableName='APTL' AND x.LINKID=@APTLKeyID)
		--INSERT dbo.vJNCT_APInvoice_POPurchase (InvoiceID, POID)
		--SELECT @APTLKeyID, @POKeyID
		--WHERE NOT EXISTS(SELECT 1 FROM dbo.vJNCT_APInvoice_POPurchase x 
		--		WHERE x.InvoiceID=@APTLKeyID AND x.POID=@POKeyID)
		END
	
	---- we now need to establish relationships to PM PCO table (PMOP) if needed
	---- this will only happen if there is purchase order detail in PMMF for the PO
	---- and assigned to a PCO.
	IF EXISTS(SELECT TOP 1 1 FROM dbo.bPMMF WHERE POCo=@APCo AND PO=@PO AND ISNULL(PCO,'') <> '')
		BEGIN
		INSERT dbo.PMRelateRecord(RECID, RecTableName, LinkTableName, LINKID)
		SELECT DISTINCT(p.KeyID), 'PMOP', 'APTL', @APTLKeyID
		FROM dbo.bPMMF m 
		INNER JOIN dbo.bPMOP p ON p.PMCo=m.PMCo
		AND p.Project=m.Project
		AND p.PCOType=m.PCOType
		AND p.PCO=m.PCO
		WHERE m.POCo = @APCo
		AND m.PO = @PO
		AND ISNULL(m.PCO,'') IS NOT NULL
		AND NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord x WHERE x.RecTableName = 'PMOP' 
				AND x.RECID=p.KeyID AND x.LinkTableName='APTL' AND x.LINKID=@APTLKeyID)

		----INSERT dbo.vJNCT_PMPCO_APPOInvoice ( InvoiceID, PCOID, POID )
		----SELECT DISTINCT(p.KeyID), @APTLKeyID, @POKeyID
		----FROM dbo.bPMMF m 
		----INNER JOIN dbo.bPMOP p ON p.PMCo=m.PMCo
		----AND p.Project=m.Project
		----AND p.PCOType=m.PCOType
		----AND p.PCO=m.PCO
		----WHERE m.POCo = @APCo
		----AND m.PO = @PO
		----AND ISNULL(m.PCO,'') IS NOT NULL
		----AND NOT EXISTS(SELECT 1 FROM dbo.vJNCT_PMPCO_APPOInvoice x 
		----		WHERE x.InvoiceID=@APTLKeyID AND x.PCOID=p.KeyID AND x.POID=@POKeyID)
		END
		
		
	---- we now need to establish relationship to PM ACO table (PMOH) if needed
	---- this will only happen if there is purchase order detail in PMMF for the PO
	---- and assigned to a ACO.
	IF EXISTS(SELECT TOP 1 1 FROM dbo.bPMMF WHERE POCo=@APCo AND PO=@PO AND ISNULL(ACO,'') <> '')
		BEGIN
		INSERT dbo.PMRelateRecord(RECID, RecTableName, LinkTableName, LINKID)
		SELECT DISTINCT(p.KeyID), 'PMOH', 'APTL', @APTLKeyID
		FROM dbo.bPMMF m 
		INNER JOIN dbo.bPMOH p ON p.PMCo=m.PMCo
		AND p.Project=m.Project
		AND p.ACO=m.ACO
		WHERE m.POCo = @APCo
		AND m.PO = @PO
		AND ISNULL(m.ACO,'') IS NOT NULL
		AND NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord x WHERE x.RecTableName = 'PMOH' 
				AND x.RECID=p.KeyID AND x.LinkTableName='APTL' AND x.LINKID=@APTLKeyID)
		
		--INSERT dbo.vJNCT_PMACO_APPOInvoice ( InvoiceID, ACOID, POID )
		--SELECT @APTLKeyID, p.KeyID, @POKeyID
		--FROM dbo.bPMMF m 
		--INNER JOIN dbo.bPMOH p ON p.PMCo=m.PMCo
		--AND p.Project=m.Project
		--AND p.ACO=m.ACO
		--WHERE m.POCo = @APCo
		--AND m.PO = @PO
		--AND ISNULL(m.ACO,'') IS NOT NULL
		--AND NOT EXISTS(SELECT 1 FROM dbo.vJNCT_PMACO_APPOInvoice x 
		--		WHERE x.InvoiceID=@APTLKeyID AND x.ACOID=p.KeyID AND x.POID=@POKeyID)
		END
		
	END


---- manage association for APTL to SL - line type = 7
IF @LineType = 7
	BEGIN
	---- GET SL KEY ID IF EXISTS
	SELECT @SLKeyID=KeyID
	FROM dbo.bSLHD WHERE SLCo=@APCo AND SL=@SL
	IF @@ROWCOUNT = 0 GOTO bspexit
	
	---- establish relationship if mode = 'I' and not already exists
	IF @Mode = 'I'
		BEGIN
		INSERT dbo.PMRelateRecord (RecTableName, RECID, LinkTableName, LINKID)
		SELECT 'SLHD', @SLKeyID, 'APTL', @APTLKeyID
		WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord x WHERE x.RecTableName='SLHD'
					AND x.RECID=@SLKeyID AND x.LinkTableName='APTL' AND x.LINKID=@APTLKeyID)
		
		--INSERT dbo.vJNCT_APInvoice_SLSubcontract (InvoiceID, SLID)
		--SELECT @APTLKeyID, @SLKeyID
		--WHERE NOT EXISTS(SELECT 1 FROM dbo.vJNCT_APInvoice_SLSubcontract x 
		--		WHERE x.InvoiceID=@APTLKeyID AND x.SLID=@SLKeyID)
		END
	
	---- we now need to establish relationships to PM tables if needed
	---- first to the PCO if there is one
	IF EXISTS(SELECT TOP 1 1 FROM dbo.bPMSL WHERE SLCo=@APCo AND SL=@SL AND ISNULL(PCO,'') <> '')
		BEGIN
		INSERT dbo.PMRelateRecord(RECID, RecTableName, LinkTableName, LINKID)
		SELECT DISTINCT(p.KeyID), 'PMOP', 'APTL', @APTLKeyID
		FROM dbo.bPMSL m 
		INNER JOIN dbo.bPMOP p ON p.PMCo=m.PMCo
		AND p.Project=m.Project
		AND p.PCOType=m.PCOType
		AND p.PCO=m.PCO
		WHERE m.SLCo = @APCo
		AND m.SL = @SL
		AND ISNULL(m.PCO,'') IS NOT NULL
		AND NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord x WHERE x.RecTableName = 'PMOP' 
				AND x.RECID=p.KeyID AND x.LinkTableName='APTL' AND x.LINKID=@APTLKeyID)
		
		----INSERT dbo.vJNCT_PMPCO_APSLInvoice ( InvoiceID, PCOID, SLID )
		----SELECT @APTLKeyID, p.KeyID, @SLKeyID
		----FROM dbo.bPMSL s 
		----INNER JOIN dbo.bPMOP p ON p.PMCo=s.PMCo
		----AND p.Project=s.Project
		----AND p.PCOType=s.PCOType
		----AND p.PCO=s.PCO
		----WHERE s.SLCo = @APCo
		----AND s.SL = @SL
		----AND ISNULL(s.PCO,'') IS NOT NULL
		----AND NOT EXISTS(SELECT 1 FROM dbo.vJNCT_PMPCO_APSLInvoice x 
		----		WHERE x.InvoiceID=@APTLKeyID AND x.PCOID=p.KeyID AND x.SLID=@SLKeyID)
		END
		

	---- we now need to establish relationship to PM ACO table (PMOH) if needed
	---- this will only happen if there is purchase order detail in PMMF for the PO
	---- and assigned to a ACO.
	IF EXISTS(SELECT TOP 1 1 FROM dbo.bPMSL WHERE SLCo=@APCo AND SL=@SL AND ISNULL(ACO,'') <> '')
		BEGIN
		INSERT dbo.PMRelateRecord(RECID, RecTableName, LinkTableName, LINKID)
		SELECT DISTINCT(p.KeyID), 'PMOH', 'APTL', @APTLKeyID
		FROM dbo.bPMSL m 
		INNER JOIN dbo.bPMOH p ON p.PMCo=m.PMCo
		AND p.Project=m.Project
		AND p.ACO=m.ACO
		WHERE m.SLCo = @APCo
		AND m.SL = @SL
		AND ISNULL(m.ACO,'') IS NOT NULL
		AND NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord x WHERE x.RecTableName = 'PMOH' 
				AND x.RECID=p.KeyID AND x.LinkTableName='APTL' AND x.LINKID=@APTLKeyID)
		
		----INSERT dbo.vJNCT_PMACO_APSLInvoice ( InvoiceID, ACOID, SLID )
		----SELECT @APTLKeyID, p.KeyID, @SLKeyID
		----FROM dbo.bPMSL s 
		----INNER JOIN dbo.bPMOH p ON p.PMCo=s.PMCo
		----AND p.Project=s.Project
		----AND p.ACO=s.ACO
		----WHERE s.SLCo = @APCo
		----AND s.SL = @SL
		----AND ISNULL(s.ACO,'') IS NOT NULL
		----AND NOT EXISTS(SELECT 1 FROM dbo.vJNCT_PMACO_APSLInvoice x 
		----		WHERE x.InvoiceID=@APTLKeyID AND x.ACOID=p.KeyID AND x.SLID=@SLKeyID)
		END
		
	END
		
		
		
		


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMAssocAPInvoice] TO [public]
GO
