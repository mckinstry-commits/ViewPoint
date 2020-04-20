SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[DDFIShared]
 
AS
SELECT     ISNULL(c.Form, d.Form) AS Form, ISNULL(c.Seq, d.Seq) AS Seq, ISNULL(c.ViewName, d.ViewName) AS ViewName, ISNULL(c.ColumnName, d.ColumnName) 
                      AS ColumnName, ISNULL(c.Description, d.Description) AS Description, ISNULL(c.Datatype, d.Datatype) AS Datatype, ISNULL(c.InputType, d.InputType) AS InputType, 
                      ISNULL(c.InputMask, d.InputMask) AS InputMask, ISNULL(c.InputLength, d.InputLength) AS InputLength, ISNULL(c.Prec, d.Prec) AS Prec, ISNULL(c.ActiveLookup, 
                      d.ActiveLookup) AS ActiveLookup, ISNULL(c.LookupParams, d.LookupParams) AS LookupParams, ISNULL(c.LookupLoadSeq, d.LookupLoadSeq) AS LookupLoadSeq, 
                      ISNULL(c.SetupForm, d.SetupForm) AS SetupForm, ISNULL(c.SetupParams, d.SetupParams) AS SetupParams, ISNULL(c.StatusText, d.StatusText) AS StatusText, 
                      ISNULL(c.Tab, d.Tab) AS Tab, ISNULL(c.Req, d.Req) AS Req, d.ValProc AS ValProc, d.ValParams AS ValParams, d.ValLevel AS ValLevel, 
                      c.ValProc AS SecondaryValProc, c.ValParams AS SecondaryValParams, c.ValLevel AS SecondaryValLevel, ISNULL(c.UpdateGroup, d.UpdateGroup) AS UpdateGroup, 
                      ISNULL(c.ControlType, d.ControlType) AS ControlType, c.ControlPosition, ISNULL(c.FieldType, d.FieldType) AS FieldType, d.HelpKeyword, d.DescriptionColumn, 
                      ISNULL(c.GridCol, d.GridCol) AS GridCol, ISNULL(c.DefaultType, 0) AS DefaultType, c.DefaultValue, ISNULL(c.InputSkip, 'N') AS InputSkip, c.Label, ISNULL(c.ShowForm, 
                      d.ShowForm) AS ShowForm, ISNULL(c.ShowGrid, d.ShowGrid) AS ShowGrid, ISNULL(c.AutoSeqType, d.AutoSeqType) AS AutoSeqType, ISNULL(c.MinValue, d.MinValue) 
                      AS MinValue, ISNULL(c.MaxValue, d.MaxValue) AS MaxValue, ISNULL(c.ValExpression, d.ValExpression) AS ValExpression, ISNULL(c.ValExpError, d.ValExpError) 
                      AS ValExpError, ISNULL(c.ComboType, d.ComboType) AS ComboType, d.GridColHeading, ISNULL(c.HeaderLinkSeq, 
                      d.HeaderLinkSeq) AS HeaderLinkSeq, c.CustomControlSize, ISNULL(c.Computed, d.Computed) AS Computed, ISNULL(c.ShowDesc, d.ShowDesc) AS ShowDesc, 
                      ISNULL(c.ColWidth, d.ColWidth) AS ColWidth, ISNULL(c.DescriptionColWidth, d.DescriptionColWidth) AS DescriptionColWidth, ISNULL(c.IsFormFilter, d.IsFormFilter) 
                      AS IsFormFilter, CASE WHEN c.Form IS NOT NULL AND d .Form IS NULL THEN 'Y' ELSE 'N' END AS Custom, CASE WHEN c.Form IS NULL AND d .Form IS NOT NULL 
                      THEN 'Standard' WHEN c.Form IS NOT NULL AND d .Form IS NOT NULL THEN 'Override' WHEN c.Form IS NOT NULL AND d .Form IS NULL 
                      THEN 'Custom' END AS Status, d.LabelTextID, d.ColumnTextID, d.ShowInQueryFilter, d.ShowInQueryResultSet, d.QueryColumnName, d.ExcludeFromRecordCopy, 
                      c.GridColHeading AS CustomGridColHeading, ISNULL(c.ExcludeFromAggregation, d.ExcludeFromAggregation) AS ExcludeFromAggregation
FROM         dbo.vDDFIc AS c FULL OUTER JOIN
                      dbo.vDDFI AS d ON d.Form = c.Form AND d.Seq = c.Seq 





GO
GRANT SELECT ON  [dbo].[DDFIShared] TO [public]
GRANT INSERT ON  [dbo].[DDFIShared] TO [public]
GRANT DELETE ON  [dbo].[DDFIShared] TO [public]
GRANT UPDATE ON  [dbo].[DDFIShared] TO [public]
GO
