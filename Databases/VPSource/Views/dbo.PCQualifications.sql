SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Create date:
-- Modified by:	GF 01/30/2012 TK-12065 #145640 APVM.TaxId
--
--
-- =============================================


CREATE VIEW [dbo].[PCQualifications]
AS
SELECT     dbo.APVM.VendorGroup, dbo.APVM.Vendor, dbo.APVM.GLCo, dbo.APVM.ActiveYN, dbo.APVM.Name, dbo.APVM.SortName, dbo.APVM.Phone, 
                      dbo.APVM.AddnlInfo, dbo.APVM.Address, dbo.APVM.City, dbo.APVM.State, dbo.APVM.Zip, dbo.APVM.Country, dbo.APVM.Address2, 
                      dbo.APVM.POAddress, dbo.APVM.POCity, dbo.APVM.POState, dbo.APVM.POZip, dbo.APVM.POCountry, dbo.APVM.POAddress2, dbo.APVM.Type, 
                      dbo.APVM.EMail, dbo.APVM.URL, dbo.APVM.Fax,
					----TK-12065
                      dbo.APVM.TaxId,
                      dbo.APVM.KeyID AS APVMKeyIDFromAPVM, dbo.vPCQualifications.*
FROM         dbo.APVM LEFT OUTER JOIN
                      dbo.vPCQualifications ON dbo.APVM.KeyID = dbo.vPCQualifications.APVMKeyID
                      

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[DeletePCQualifications]
   ON  [dbo].[PCQualifications]
	INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	DELETE vPCQualifications
	FROM vPCQualifications INNER JOIN DELETED ON vPCQualifications.APVMKeyID = DELETED.APVMKeyID
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Create date: Jacob VH 12/11/08
-- Modified By:	GF 01/30/2012 TK-12065 #145640 APVM.TaxId
--
--
-- Description:	The INSTEAD OF INSERT allows for inserts to be written against a view.
--		This is the trigger that defines what should be done with the inserted rows.
--		The trigger will add rows to the bAPVM table and add related vPCQualifications rows
-- =============================================
CREATE TRIGGER [dbo].[InsertPCQualifications] 
   ON  [dbo].[PCQualifications]
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [dbo].[APVM]
		(
		-- Keys
		[VendorGroup]
		,[Vendor]
		,[ActiveYN]
		
		-- NonNullable columns with default values
		,[TempYN]
		,[Purge]
		,[V1099YN]
		,[EFT]
		,[AuditYN]
		,[SeparatePayInvYN]
		,[OverrideMinAmtYN]
		,[APRefUnqOvr]
		,[UpdatePMYN]
		,[AddRevToAllLinesYN]
		,[AUVendorEFTYN]
		,[IATYN]
		
		-- NonNullable columns used in the view
		,[GLCo]
		,[SortName]
		,[Type]

		-- The columns that are used in the view
		,[Name]
		,[Phone]
		,[AddnlInfo]
		,[Address]
		,[City]
		,[State]
		,[Zip]
		,[Country]
		,[Address2]
		,[POAddress]
		,[POCity]
		,[POState]
		,[POZip]
		,[POCountry]
		,[POAddress2]
		,[EMail]
		,[URL]
		,[Fax]
		----TK-12065
		,[TaxId]
		)
	SELECT
		-- Keys
		[VendorGroup] -- VendorGroup
		,[Vendor] -- Vendor
		,[ActiveYN] -- ActiveYN
		
		-- NonNullable columns with default values
		,'N' -- TempYN
		,'N' -- Purge
		,'N' -- V1099YN
		,'N' -- EFT
		,'N' -- AuditYN
		,'N' -- SeparatePayInvYN
		,'N' -- OverrideMinAmtYN
		,0 -- APRefUnqOvr
		,'N' -- UpdatePMYN
		,'N' -- AddRevToAllLinesYN
		,'N' -- AUVendorEFTYN
		,'N' -- IATYN

		-- NonNullable columns used in the view
		,[GLCo]
		,[SortName]
		,[Type]

		-- The columns that are used in the view
		,[Name]
		,[Phone]
		,[AddnlInfo]
		,[Address]
		,[City]
		,[State]
		,[Zip]
		,[Country]
		,[Address2]
		,[POAddress]
		,[POCity]
		,[POState]
		,[POZip]
		,[POCountry]
		,[POAddress2]
		,[EMail]
		,[URL]
		,[Fax]
		----TK-12065
		,[TaxId]
	FROM INSERTED
	
	-- Since we have have a foreign key relationship from vPCQualifications to bAPVM we should not
	-- have any rouge rows in vPCQualifications that need to be updated instead of inserted
	
	SELECT INSERTED.*, APVM.KeyID AS APVMKeyIDToUpdateFrom 
	INTO #PCQualificationsTempInsertTableForInsert
	FROM INSERTED LEFT JOIN APVM
		ON INSERTED.VendorGroup = APVM.VendorGroup AND INSERTED.Vendor = APVM.Vendor
	
	-- Since we just inserted the rows into bAPVM the INSERTED table doesn't have the APVMKeyIDs set
	-- Therefore we retrieved the values in the last query and use them to update our temp table.
		
	UPDATE #PCQualificationsTempInsertTableForInsert
	SET APVMKeyID = APVMKeyIDToUpdateFrom 
	
	EXECUTE vspCreateAndExecuteInsert 'vPCQualifications', '#PCQualificationsTempInsertTableForInsert'
	
	DROP TABLE #PCQualificationsTempInsertTableForInsert
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Create date: Jacob VH 12/11/08
-- Modified by:	CHS	11/03/2009 - issue #135836
--				GF 01/30/2012 TK-12065 #145640 APVM.TaxId
--				NH 06/14/2012 - TK-15726 added case statement to update ActiveYN properly
--
-- Description:	The INSTEAD OF UPDATE allows for updates to be written against a view.
--		This is the trigger that defines what should be done with the updated rows.
--		The trigger will update rows to the bAPVM table and add/update related vPCQualifications rows
-- =============================================
CREATE TRIGGER [dbo].[UpdatePCQualifications]
   ON  [dbo].[PCQualifications]
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for trigger here
	UPDATE APVM
	SET
		-- TK-15726 - Case statement to stop ActiveYN from always being Y
		[ActiveYN] =
			case INSERTED.[Qualified]
				when 'Y' then 'Y'
				else INSERTED.[ActiveYN]
			end,
		[Name] = INSERTED.[Name],
		[SortName] = INSERTED.[SortName],
		[Phone] = INSERTED.[Phone],
		[AddnlInfo] = INSERTED.[AddnlInfo],
		[Address] = INSERTED.[Address],
		[City] = INSERTED.[City],
		[State] = INSERTED.[State],
		[Zip] = INSERTED.[Zip],
		[Country] = INSERTED.[Country],
		[Address2] = INSERTED.[Address2],
		[POAddress] = INSERTED.[POAddress],
		[POCity] = INSERTED.[POCity],
		[POState] = INSERTED.[POState],
		[POZip] = INSERTED.[POZip],
		[POCountry] = INSERTED.[POCountry],
		[POAddress2] = INSERTED.[POAddress2],
		[Type] = INSERTED.[Type],
		[EMail] = INSERTED.[EMail],
		[URL] = INSERTED.[URL],
		[Fax] = INSERTED.[Fax],
		----TK-12065
		[TaxId] = INSERTED.[TaxId]
	FROM INSERTED INNER JOIN APVM ON INSERTED.[APVMKeyIDFromAPVM] = APVM.[KeyID]

	-- Grab all the rows that do have a corresponding row in the vPCQualifications table and update them
	
	SELECT INSERTED.* 
	INTO #PCQualificationsTempUpdateTable
	FROM INSERTED LEFT JOIN vPCQualifications ON INSERTED.APVMKeyIDFromAPVM = vPCQualifications.APVMKeyID
	WHERE NOT vPCQualifications.APVMKeyID IS NULL
	
	EXECUTE vspCreateAndExecuteUpdate 'vPCQualifications', '#PCQualificationsTempUpdateTable', 'vPCQualifications.KeyID = #PCQualificationsTempUpdateTable.KeyID'

	DROP TABLE #PCQualificationsTempUpdateTable

	-- Grab all the rows that do not have a corresponding row in the vPCQualifications table and insert them

	SELECT INSERTED.* 
	INTO #PCQualificationsTempUpdateTableForInsert 
	FROM INSERTED LEFT JOIN vPCQualifications ON INSERTED.APVMKeyIDFromAPVM = vPCQualifications.APVMKeyID
	WHERE vPCQualifications.APVMKeyID IS NULL

	-- Update the APVMKeyIDs because the rows do not exist and must have APVMKeyIDs set in order to do inserts

	UPDATE #PCQualificationsTempUpdateTableForInsert 
	SET APVMKeyID = APVMKeyIDFromAPVM
	
	EXECUTE vspCreateAndExecuteInsert 'vPCQualifications', '#PCQualificationsTempUpdateTableForInsert'
	
	DROP TABLE #PCQualificationsTempUpdateTableForInsert 
END





GO
GRANT SELECT ON  [dbo].[PCQualifications] TO [public]
GRANT INSERT ON  [dbo].[PCQualifications] TO [public]
GRANT DELETE ON  [dbo].[PCQualifications] TO [public]
GRANT UPDATE ON  [dbo].[PCQualifications] TO [public]
GO
