SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPGridQueryLinks AS
	SELECT QueryName
			,RelatedQueryName
			,DisplaySeq
			,DefaultDrillThrough
			,IsStandard
			,LinksConfigured
			,KeyID
	FROM vVPGridQueryLinks

	UNION ALL
	-- use column names instead of * because of inconsistency in standard/custom table field order
	SELECT QueryName
			,RelatedQueryName
			,DisplaySeq
			,DefaultDrillThrough
			,IsStandard
			,LinksConfigured
			,KeyID						
	FROM vVPGridQueryLinksc

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: HH 3/26/2012 TK-13346
* Modified: 
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueryLinksd] 
   ON  [dbo].[VPGridQueryLinks] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @IsDefault bYN
	DECLARE @MinSeq INT

	SELECT @IsDefault = DefaultDrillThrough 
	FROM deleted

	DELETE vVPGridQueryLinks
	FROM vVPGridQueryLinks
	INNER JOIN deleted d ON vVPGridQueryLinks.KeyID = d.KeyID AND vVPGridQueryLinks.QueryName = d.QueryName AND d.IsStandard = 'Y'

	DELETE vVPGridQueryLinksc
	FROM vVPGridQueryLinksc
	INNER JOIN deleted d ON vVPGridQueryLinksc.KeyID = d.KeyID AND vVPGridQueryLinksc.QueryName = d.QueryName AND d.IsStandard = 'N'
	
	SELECT @MinSeq = Min(VPGridQueryLinks.DisplaySeq) 
	FROM VPGridQueryLinks
	INNER JOIN deleted d ON VPGridQueryLinks.QueryName = d.QueryName 
	
	IF @IsDefault = 'Y'
	BEGIN
	
		UPDATE vVPGridQueryLinks
		SET DefaultDrillThrough = 'Y'
		FROM vVPGridQueryLinks
		INNER JOIN deleted d ON vVPGridQueryLinks.QueryName = d.QueryName AND d.IsStandard = 'Y'
		WHERE vVPGridQueryLinks.DisplaySeq = @MinSeq
		
		UPDATE vVPGridQueryLinksc
		SET DefaultDrillThrough = 'Y'
		FROM vVPGridQueryLinksc
		INNER JOIN deleted d ON vVPGridQueryLinksc.QueryName = d.QueryName AND d.IsStandard = 'N'
		WHERE vVPGridQueryLinksc.DisplaySeq = @MinSeq
	
	END
	
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: HH 3/26/2012 TK-13346
* Modified: DK 05/02/2012 TK-13344
*			Added LinksConfigured 
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueryLinksi] 
   ON  [dbo].[VPGridQueryLinks] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	BEGIN
		INSERT INTO vVPGridQueryLinks ( QueryName, RelatedQueryName, DisplaySeq, DefaultDrillThrough, IsStandard, LinksConfigured )
			SELECT QueryName, RelatedQueryName, DisplaySeq, DefaultDrillThrough, 'Y', 'N' FROM inserted
	END 

ELSE
	BEGIN
		INSERT INTO vVPGridQueryLinksc ( QueryName, RelatedQueryName, DisplaySeq, DefaultDrillThrough, IsStandard, LinksConfigured )
			SELECT QueryName, RelatedQueryName, DisplaySeq, DefaultDrillThrough, 'N', 'N' FROM inserted
	END 

IF (SELECT COUNT(*) FROM inserted WHERE DefaultDrillThrough = 'Y') <> 0 
	BEGIN
	
		UPDATE		vVPGridQueryLinks SET 
					DefaultDrillThrough = 'N' 
		FROM		inserted i 
		INNER JOIN	vVPGridQueryLinks QL 
				ON	QL.QueryName = i.QueryName 
				AND QL.DisplaySeq <> i.DisplaySeq
				AND i.DefaultDrillThrough = 'Y'
				
		UPDATE		vVPGridQueryLinksc SET 
					DefaultDrillThrough = 'N' 
		FROM		inserted i 
		INNER JOIN	vVPGridQueryLinksc QL 
				ON	QL.QueryName = i.QueryName 
				AND QL.DisplaySeq <> i.DisplaySeq
				AND i.DefaultDrillThrough = 'Y'
	END 		
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: HH 3/26/2012 TK-13346
* Modified: HH 5/24/2012 TK-15181 - added LinksConfigured
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueryLinksu] 
   ON  [dbo].[VPGridQueryLinks] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE	vVPGridQueryLinks SET
			QueryName = i.QueryName,
			RelatedQueryName = i.RelatedQueryName,
			DisplaySeq = i.DisplaySeq,
			DefaultDrillThrough = i.DefaultDrillThrough,
			LinksConfigured = i.LinksConfigured
	FROM vVPGridQueryLinks
	INNER JOIN inserted i ON vVPGridQueryLinks.KeyID = i.KeyID AND vVPGridQueryLinks.QueryName = i.QueryName AND i.IsStandard = 'Y'

	UPDATE	vVPGridQueryLinksc SET
			QueryName = i.QueryName,
			RelatedQueryName = i.RelatedQueryName,
			DisplaySeq = i.DisplaySeq,
			DefaultDrillThrough = i.DefaultDrillThrough,
			LinksConfigured = i.LinksConfigured
	FROM vVPGridQueryLinksc
	INNER JOIN inserted i ON vVPGridQueryLinksc.KeyID = i.KeyID AND vVPGridQueryLinksc.QueryName = i.QueryName AND i.IsStandard = 'N'

IF (SELECT COUNT(*) FROM inserted WHERE DefaultDrillThrough = 'Y') <> 0 
	BEGIN
	
		UPDATE		vVPGridQueryLinks SET 
					DefaultDrillThrough = 'N' 
		FROM		inserted i 
		INNER JOIN	vVPGridQueryLinks QL 
				ON	QL.QueryName = i.QueryName 
				AND QL.DisplaySeq <> i.DisplaySeq
				AND i.DefaultDrillThrough = 'Y'
				
		UPDATE		vVPGridQueryLinksc SET 
					DefaultDrillThrough = 'N' 
		FROM		inserted i 
		INNER JOIN	vVPGridQueryLinksc QL 
				ON	QL.QueryName = i.QueryName 
				AND QL.DisplaySeq <> i.DisplaySeq
				AND i.DefaultDrillThrough = 'Y'
	END 		

END
GO
GRANT SELECT ON  [dbo].[VPGridQueryLinks] TO [public]
GRANT INSERT ON  [dbo].[VPGridQueryLinks] TO [public]
GRANT DELETE ON  [dbo].[VPGridQueryLinks] TO [public]
GRANT UPDATE ON  [dbo].[VPGridQueryLinks] TO [public]
GRANT SELECT ON  [dbo].[VPGridQueryLinks] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPGridQueryLinks] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPGridQueryLinks] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPGridQueryLinks] TO [Viewpoint]
GO
