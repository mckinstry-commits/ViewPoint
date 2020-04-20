SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of PM Firm Contacts for
   * use in the list box's displayed in the
   * distribution forms.
   *
   *****************************************/
   
   CREATE view [dbo].[PMPFList] as 
   select top 100 percent a.*, 'FirmName'=b.SortName, 'ContactName'=c.SortName
   FROM dbo.PMPF a
   LEFT JOIN dbo.PMFM b with (nolock) ON b.VendorGroup=a.VendorGroup and b.FirmNumber=a.FirmNumber
   LEFT JOIN dbo.PMPM c with (nolock) ON c.VendorGroup=a.VendorGroup and c.FirmNumber=a.FirmNumber and c.ContactCode=a.ContactCode
   order by a.PMCo, a.Project, a.VendorGroup, a.FirmNumber, a.ContactCode


GO
GRANT SELECT ON  [dbo].[PMPFList] TO [public]
GRANT INSERT ON  [dbo].[PMPFList] TO [public]
GRANT DELETE ON  [dbo].[PMPFList] TO [public]
GRANT UPDATE ON  [dbo].[PMPFList] TO [public]
GRANT SELECT ON  [dbo].[PMPFList] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPFList] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPFList] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPFList] TO [Viewpoint]
GO
