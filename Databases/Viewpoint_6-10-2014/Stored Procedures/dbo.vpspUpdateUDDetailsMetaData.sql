SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Chris G
-- Create date: 8/23/12
-- Description:	Updates UD Fields in Connects Details Control.
--				NOTE: The details controls have a 3x3 grid
--				layout, with fields scattered amongst any combination
--				of the 3x3 layout.  We'll place the UD fields above
--				any Notes (textarea) field and below all other fields.
--				This is an approximation of the best fit so this will
--				work in some cases but not all.
-- =============================================
CREATE PROCEDURE [dbo].[vpspUpdateUDDetailsMetaData] 
	(@portalControlId INT, @view VARCHAR(128))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	DECLARE @htmlTables TABLE (HTMLTableID INT, Seq INT)
	DECLARE @detailsID INT
	
	-- Populate a Temp table from pPortalControlLayout for the given PortalControlID in reverse order
	INSERT INTO @htmlTables 
		SELECT BottomRightTableID, 1 FROM pPortalControlLayout WHERE PortalControlID = @portalControlId UNION
		SELECT BottomCenterTableID, 2 FROM pPortalControlLayout WHERE PortalControlID = @portalControlId UNION
		SELECT BottomLeftTableID, 3 FROM pPortalControlLayout WHERE PortalControlID = @portalControlId UNION
		SELECT CenterRightTableID, 4 FROM pPortalControlLayout WHERE PortalControlID = @portalControlId UNION
		SELECT CenterCenterTableID, 5 FROM pPortalControlLayout WHERE PortalControlID = @portalControlId UNION
		SELECT CenterLeftTableID, 6 FROM pPortalControlLayout WHERE PortalControlID = @portalControlId UNION
		SELECT TopRightTableID, 7 FROM pPortalControlLayout WHERE PortalControlID = @portalControlId UNION
		SELECT TopCenterTableID, 8 FROM pPortalControlLayout WHERE PortalControlID = @portalControlId UNION
		SELECT TopLeftTableID, 9 FROM pPortalControlLayout WHERE PortalControlID = @portalControlId
	
	-- Find a suitable Details control by searching from bottom/right to top/left (reverse) in the
	-- ControlLayout table.  Take the lowest/right most one that is not a notes control.
	
	SELECT TOP 1 @detailsID = d.DetailsID
	      FROM @htmlTables tht 
	INNER JOIN pPortalHTMLTables h ON h.HTMLTableID = tht.HTMLTableID
    INNER JOIN pPortalDetails d ON d.DetailsID = h.DetailsID
    INNER JOIN pPortalDetailsField df ON df.DetailsID = d.DetailsID AND df.ColumnName <> 'Notes'
	  ORDER BY tht.Seq
	
	-- Clean out the previous UD fields
	DELETE FROM pPortalDetailsFieldCustom WHERE DetailsID = @detailsID AND ColumnName like 'ud%'
	
	DECLARE @maxStandardFieldOrder INT, @newDetailsFieldID INT
	SELECT @maxStandardFieldOrder = MAX(DetailsFieldOrder) FROM pvDetailsField WHERE DetailsID = @detailsID
	SELECT @newDetailsFieldID = MAX(DetailsFieldID) FROM pPortalDetailsFieldCustom
	
	-- Generate a details field id, 100000+ denotes a UD field
	IF @newDetailsFieldID IS NULL OR @newDetailsFieldID < 100000
	BEGIN
		SET @newDetailsFieldID = 100000
	END
	ELSE
	BEGIN
		SET @newDetailsFieldID = @newDetailsFieldID + 1
	END
		
	-- Insert directly into the Custom table.  This is to separate UD fields from Standard fields.
	INSERT INTO pPortalDetailsFieldCustom 
	(DetailsFieldID, DetailsID, ColumnName, LabelText, Editable, [Required], TextMode, MaxLength, Visible, DetailsFieldOrder, DataFormatID, HasLookup)
	(    
		 SELECT ROW_NUMBER() OVER (ORDER BY Seq) + @newDetailsFieldID -- DetailsFieldID
		       ,@detailsID
	           ,ColumnName
	           ,Label
  			   ,1 -- Editable
	           ,CASE Req WHEN 'Y' THEN 1 ELSE 0 END -- Required
	           ,1 -- TextMode
	           ,InputLength
	           ,1 -- Visible
	           ,ROW_NUMBER() OVER (ORDER BY Seq) + @maxStandardFieldOrder -- DetailsFieldOrder
	           ,dbo.vfUDGetDataFormatID(@view, ColumnName) -- DataFormatID
	           ,case when exists(select 1 from vDDFLc b where a.Form = b.Form and a.Seq = b.Seq and b.Active = 'Y') then 1 else 0 end As HasLookup
	       FROM DDFIc a
	      WHERE ViewName = @view
	        AND ColumnName like 'ud%'
	 )
END
GO
GRANT EXECUTE ON  [dbo].[vpspUpdateUDDetailsMetaData] TO [VCSPortal]
GO
