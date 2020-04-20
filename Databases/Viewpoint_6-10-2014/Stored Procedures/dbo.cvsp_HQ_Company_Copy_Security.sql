SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure [dbo].[cvsp_HQ_Company_Copy_Security] ******/
CREATE PROCEDURE [dbo].[cvsp_HQ_Company_Copy_Security]
/*=======================================================================================
Copyright © 2014 Viewpoint Construction Software (VCS) 
The T-SQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
Title:	VCS Company Copy Security
Created:	2014
Created by:	VCS Technical Services
Revisions:	1. 

Notes: 

=======================================================================================*/
(
	@FromCo	bCompany,
	@ToCo	bCompany
)
AS
	SET NOCOUNT ON

	DECLARE @ErrNumber		int,
			@ErrMessage		nvarchar(4000),
			@ErrSeverity	int,
			@ErrState		int,
			@ErrProcedure	nvarchar(128),
			@ErrLine		int

	PRINT 'Copying Company ' + CAST(@FromCo AS varchar) + ' Security to Company ' + CAST(@ToCo AS varchar)

	BEGIN TRANSACTION
	BEGIN TRY
		/* bPRGS: PR Group Security */
		INSERT INTO bPRGS (
			PRCo, PRGroup, VPUserName
		)
		SELECT
			@ToCo, gs.PRGroup, gs.VPUserName
		FROM bPRGS AS gs
		INNER JOIN HQGP AS gp
			ON gp.Grp = gs.PRGroup
			AND gp.Grp != 0
		INNER JOIN vDDUP AS up
			ON up.VPUserName = gs.VPUserName
		LEFT OUTER JOIN bPRGS AS gse
			ON gse.PRCo = @ToCo
			AND gse.PRGroup = gs.PRGroup
			AND gse.VPUserName = gs.VPUserName
		WHERE gs.PRCo = @FromCo
		AND gse.PRCo IS NULL
		PRINT 'bPRGS Inserted: ' + CAST(@@ROWCOUNT AS varchar)

		/* vDDDS: DD Data Security */
		INSERT INTO vDDDS (
			Datatype, Qualifier, Instance, SecurityGroup
		)
		SELECT
			ds.Datatype, @ToCo, ds.Instance, ds.SecurityGroup
		FROM vDDDS AS ds
		INNER JOIN vDDSG AS sg
			ON sg.SecurityGroup = ds.SecurityGroup
		LEFT OUTER JOIN vDDDS AS dse
			ON dse.Datatype = ds.Datatype
			AND dse.Qualifier = @ToCo
			AND dse.Instance = ds.Instance
			AND dse.SecurityGroup = ds.SecurityGroup
		WHERE ds.Qualifier = @FromCo
		AND dse.Datatype IS NULL
		PRINT 'vDDDS Inserted: ' + CAST(@@ROWCOUNT AS varchar)

		/* vDDDU: DD Data Instance User */
		INSERT INTO vDDDU (
			Datatype, Qualifier, Instance, VPUserName, Employee
		)
		SELECT
			du.Datatype, @ToCo, du.Instance, du.VPUserName, du.Employee
		FROM vDDDU AS du
		INNER JOIN vDDUP AS up
			ON up.VPUserName = du.VPUserName
		LEFT OUTER JOIN vDDDU AS due
			ON due.Datatype = du.Datatype
			AND due.Qualifier = @ToCo
			AND due.Instance = du.Instance
			AND due.VPUserName = du.VPUserName
		WHERE du.Qualifier = @FromCo
		AND due.Datatype IS NULL
		PRINT 'vDDDU Inserted: ' + CAST(@@ROWCOUNT AS varchar)

		/* vDDFS: DD Form Security */
		INSERT INTO vDDFS (
			Co, Form, SecurityGroup, VPUserName, Access, RecAdd, RecUpdate, RecDelete, AttachmentSecurityLevel
		)
		SELECT
			@ToCo, fs.Form, fs.SecurityGroup, fs.VPUserName, fs.Access, fs.RecAdd, fs.RecUpdate, fs.RecDelete, fs.AttachmentSecurityLevel
		FROM vDDFS AS fs
		INNER JOIN vDDSG AS sg
			ON sg.SecurityGroup = fs.SecurityGroup
		INNER JOIN vDDUP AS up
			ON up.VPUserName = fs.VPUserName
		LEFT OUTER JOIN vDDFS AS fse
			ON fse.Co = @ToCo
			AND fse.Form = fs.Form
			AND fse.SecurityGroup = fs.SecurityGroup
			AND fse.VPUserName = fs.VPUserName
		WHERE fs.Co = @FromCo
		AND fse.Co IS NULL
		PRINT 'vDDFS Inserted: ' + CAST(@@ROWCOUNT AS varchar)

		/* vDDSF: */
		INSERT INTO vDDSF (
			Co, VPUserName, Mod, SubFolder, Title, ViewOptions
		)
		SELECT
			@ToCo, sf.VPUserName, sf.Mod, sf.SubFolder, sf.Title, sf.ViewOptions 
		FROM vDDSF AS sf
		INNER JOIN vDDUP AS up
			ON up.VPUserName = sf.VPUserName
		LEFT OUTER JOIN vDDSF AS sfe
			ON sfe.Co = @ToCo
			AND sfe.VPUserName = sf.VPUserName
			AND sfe.Mod = sf.Mod
			AND sfe.SubFolder = sf.SubFolder
		WHERE sf.Co=@FromCo
		AND sf.SubFolder > 0
		AND sfe.Co IS NULL
		PRINT 'vDDSF Inserted: ' + CAST(@@ROWCOUNT AS varchar)

		/* vDDSI: */
		INSERT INTO vDDSI (
			Co, VPUserName, Mod, SubFolder, ItemType, MenuItem, MenuSeq
		)
		SELECT
			@ToCo, si.VPUserName, si.Mod, si.SubFolder, si.ItemType, si.MenuItem, si.MenuSeq 
		FROM vDDSI AS si
		INNER JOIN vDDUP AS up
			ON up.VPUserName = si.VPUserName
		LEFT OUTER JOIN vDDSI AS sie
			ON sie.Co = @ToCo
			AND sie.VPUserName = si.VPUserName
			AND sie.Mod = si.Mod
			AND sie.SubFolder = si.SubFolder
			AND sie.ItemType = si.ItemType
			AND sie.MenuItem = si.MenuItem
		WHERE si.Co = @FromCo
		AND si.SubFolder > 0
		AND sie.Co IS NULL
		PRINT 'vDDSI Inserted: ' + CAST(@@ROWCOUNT AS varchar)

		/* vDDTS: DD Tab Security */
		INSERT INTO vDDTS (
			Co, Form, Tab, SecurityGroup, VPUserName, Access
		)
		SELECT
			@ToCo, ts.Form, ts.Tab, ts.SecurityGroup, ts.VPUserName, ts.Access
		FROM vDDTS AS ts
		INNER JOIN vDDSG AS sg
			ON sg.SecurityGroup = ts.SecurityGroup
		INNER JOIN vDDUP AS up
			ON up.VPUserName = ts.VPUserName
		LEFT OUTER JOIN vDDTS AS tse
			ON tse.Co = @ToCo
			AND tse.Form = ts.Form
			AND tse.Tab = ts.Tab
			AND tse.SecurityGroup = ts.SecurityGroup
			AND tse.VPUserName = ts.VPUserName
		WHERE ts.Co = @FromCo
		AND tse.Co IS NULL
		PRINT 'vDDTS Inserted: ' + CAST(@@ROWCOUNT AS varchar)

		/* vRPRS: RP Report Security */
		INSERT INTO vRPRS (
			Co, ReportID, SecurityGroup, VPUserName, Access
		)
		SELECT
			@ToCo, rs.ReportID, rs.SecurityGroup, rs.VPUserName, rs.Access
		FROM vRPRS AS rs
		INNER JOIN vDDSG AS sg
			ON sg.SecurityGroup = rs.SecurityGroup
		INNER JOIN vDDUP AS up
			ON up.VPUserName = rs.VPUserName
		LEFT OUTER JOIN vRPRS AS rse
			ON rse.Co = @ToCo
			AND rse.ReportID = rs.ReportID
			AND rse.SecurityGroup = rs.SecurityGroup
			AND rse.VPUserName = rs.VPUserName
		WHERE rs.Co = @FromCo
		AND rse.Co IS NULL
		PRINT 'vRPRS Inserted: ' + CAST(@@ROWCOUNT AS varchar)

		/* vVAAttachmentTypeSecurity: VA Attachment Type Security */
		INSERT INTO vVAAttachmentTypeSecurity (
			Co, AttachmentTypeID, SecurityGroup, VPUserName, Access
		)
		SELECT
			@ToCo, ats.AttachmentTypeID, ats.SecurityGroup, ats.VPUserName, ats.Access
		FROM vVAAttachmentTypeSecurity AS ats
		INNER JOIN vDDSG AS sg
			ON sg.SecurityGroup = ats.SecurityGroup
		INNER JOIN vDDUP AS up
			ON up.VPUserName = ats.VPUserName
		LEFT OUTER JOIN vVAAttachmentTypeSecurity AS atse
			ON atse.Co = @ToCo
			AND atse.AttachmentTypeID = ats.AttachmentTypeID
			AND atse.SecurityGroup = ats.SecurityGroup
			AND atse.VPUserName = ats.VPUserName
		WHERE ats.Co = @FromCo
		AND atse.Co IS NULL
		PRINT 'vVAAttachmentTypeSecurity Inserted: ' + CAST(@@ROWCOUNT AS varchar)

		/* vVPCanvasTemplateSecurity: */
		INSERT INTO vVPCanvasTemplateSecurity (
			Co, TemplateName, SecurityGroup, VPUserName, Access
		)
		SELECT
			@ToCo, cts.TemplateName, cts.SecurityGroup, cts.VPUserName, cts.Access
		FROM vVPCanvasTemplateSecurity AS cts
		INNER JOIN vDDSG AS sg
			ON sg.SecurityGroup = cts.SecurityGroup
		INNER JOIN vDDUP AS up
			ON up.VPUserName = cts.VPUserName
		LEFT OUTER JOIN vVPCanvasTemplateSecurity AS ctse
			ON ctse.Co = @ToCo
			AND ctse.TemplateName = cts.TemplateName
			AND ctse.SecurityGroup = cts.SecurityGroup
			AND ctse.VPUserName = cts.VPUserName
		WHERE cts.Co = @FromCo
		AND ctse.Co IS NULL
		PRINT 'vVPCanvasTemplateSecurity Inserted: ' + CAST(@@ROWCOUNT AS varchar)

		/* vVPQuerySecurity: */
		INSERT INTO vVPQuerySecurity (
			Co, QueryName, SecurityGroup, VPUserName, Access
		)
		SELECT
			@ToCo, qs.QueryName, qs.SecurityGroup, qs.VPUserName, qs.Access
		FROM vVPQuerySecurity AS qs
		INNER JOIN vDDSG AS sg
			ON sg.SecurityGroup = qs.SecurityGroup
		INNER JOIN vDDUP AS up
			ON up.VPUserName = qs.VPUserName
		LEFT OUTER JOIN vVPQuerySecurity AS qse
			ON qse.Co = @ToCo
			AND qse.QueryName = qs.QueryName
			AND qse.SecurityGroup = qs.SecurityGroup
			AND qse.VPUserName = qs.VPUserName
		WHERE qs.Co = @FromCo
		AND qse.Co IS NULL
		PRINT 'vVPQuerySecurity Inserted: ' + CAST(@@ROWCOUNT AS varchar)
		
		COMMIT TRANSACTION

		PRINT CHAR(9) + 'Company ' + CAST(@ToCo AS varchar) + ' Security copied'
	END TRY
	BEGIN CATCH
		SELECT @ErrNumber = ERROR_NUMBER(),
				@ErrMessage = ERROR_MESSAGE(),
				@ErrSeverity = ERROR_SEVERITY(),
				@ErrState = ERROR_STATE(),
				@ErrProcedure = ERROR_PROCEDURE(),
				@ErrLine = ERROR_LINE()

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

		PRINT CHAR(9) + 'Company ' + CAST(@ToCo AS varchar) + ' Security NOT copied'

		RAISERROR(@ErrMessage, @ErrSeverity, @ErrState);
	END CATCH  
GO
