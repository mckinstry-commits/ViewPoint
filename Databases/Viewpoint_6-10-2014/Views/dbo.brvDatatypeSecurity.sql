SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvDatatypeSecurity]
/******************************************
* Created: ??
* Modified: GG - 02/10/06 - VP6 changes
*
* View for datatype security reports
*
*****************************************/
as
   

/*  SELECT DDDU.Datatype, DDDU.Qualifier, DDDU.Instance, DDDU.VPUserName,
      DDDS.SecurityGroup, DDSG.Description
  FROM DDDU 
    Left outer Join DDDS ON DDDU.Datatype = DDDS.Datatype AND DDDU.Qualifier = DDDS.Qualifier AND 
                            DDDU.Instance = DDDS.Instance
    Left outer Join DDSU ON DDDU.VPUserName = DDSU.VPUserName and DDDS.SecurityGroup=DDSU.SecurityGroup
    Left outer Join DDSG ON DDSU.SecurityGroup = DDSG.SecurityGroup*/


/*select ds.Datatype, ds.Qualifier, ds.Instance, ds.SecurityGroup, sg.Name, su.VPUserName
from dbo.vDDDS ds (nolock)
left join dbo.vDDSG sg (nolock) on sg.SecurityGroup = ds.SecurityGroup
left join dbo.vDDSU su (nolock) on su.SecurityGroup = ds.SecurityGroup*/

-- must start with vDDDU instead on vDDDS because security on bEmployee can use PR Groups not DD Security Groups
select top 100 percent du.Datatype, du.Qualifier, du.Instance, sa.SecurityGroup, sg.Name, du.VPUserName
from dbo.vDDDU du (nolock)
left join (select ds.Datatype, ds.Qualifier, ds.Instance, ds.SecurityGroup, su.VPUserName
		from dbo.vDDDS ds (nolock)
		join dbo.vDDSU su (nolock) on su.SecurityGroup = ds.SecurityGroup) as sa
	on sa.Datatype = du.Datatype and sa.Qualifier = du.Qualifier
		and sa.Instance = du.Instance and sa.VPUserName = du.VPUserName
left join dbo.vDDSG sg (nolock) on sa.SecurityGroup = sg.SecurityGroup
order by du.Datatype, du.Qualifier, du.Instance, sa.SecurityGroup, du.VPUserName

GO
GRANT SELECT ON  [dbo].[brvDatatypeSecurity] TO [public]
GRANT INSERT ON  [dbo].[brvDatatypeSecurity] TO [public]
GRANT DELETE ON  [dbo].[brvDatatypeSecurity] TO [public]
GRANT UPDATE ON  [dbo].[brvDatatypeSecurity] TO [public]
GRANT SELECT ON  [dbo].[brvDatatypeSecurity] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvDatatypeSecurity] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvDatatypeSecurity] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvDatatypeSecurity] TO [Viewpoint]
GO
