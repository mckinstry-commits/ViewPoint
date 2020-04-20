SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************************
   *	Created:	
   *	Modified:	DANF 02/23/2005
   *
   *	View for the VAPurgeSecurityEntries form.
   *
   ********************************************************/
   
   CREATE   view [dbo].[DDDSPurge] 
   as 
   select top 100 percent s.* 
   from dbo.vDDDS s with (nolock)
   order by s.Datatype, s.Qualifier, s.Instance

GO
GRANT SELECT ON  [dbo].[DDDSPurge] TO [public]
GRANT INSERT ON  [dbo].[DDDSPurge] TO [public]
GRANT DELETE ON  [dbo].[DDDSPurge] TO [public]
GRANT UPDATE ON  [dbo].[DDDSPurge] TO [public]
GO
