SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************
   *
   *	Created By MH 
   *	Created ??
   *
   *	Used by HRAccidentDetail BodyParts grid to 
   *	get BodyPartCode Description and InjuryCode Description.
   *
   *
   *
   ***************************************/
   
   
    
    CREATE   view [dbo].[HRADMAIN] as select d.HRCo as 'HRCo', d.Accident as 'Accident', d.Seq as 'Seq',
      	BodyPart = d.BodyPart, BodyDesc = c1.Description, InjuryType = d.InjuryType, InjuryDesc = c2.Description
      from dbo.HRAD d with (nolock)
      join dbo.bHRCM c1 with (nolock) on c1.HRCo = d.HRCo and c1.Code = d.BodyPart
      join dbo.bHRCM c2 with (nolock) on c2.HRCo = d.HRCo and c2.Code = d.InjuryType
      where c1.Type = 'B' and c2.Type = 'I'

GO
GRANT SELECT ON  [dbo].[HRADMAIN] TO [public]
GRANT INSERT ON  [dbo].[HRADMAIN] TO [public]
GRANT DELETE ON  [dbo].[HRADMAIN] TO [public]
GRANT UPDATE ON  [dbo].[HRADMAIN] TO [public]
GO
