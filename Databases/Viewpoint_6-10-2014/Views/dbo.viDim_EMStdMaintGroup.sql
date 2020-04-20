SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viDim_EMStdMaintGroup] AS


select 
bEMCO.KeyID AS EMCoID,
EMSH.KeyID as 'StdMaintGroupID',
row_number() over (order by EMSI.EMCo, EMSI.Equipment, EMSI.StdMaintGroup, EMSI.StdMaintItem ) as 'StdMaintItemID',
EMSH.Description as 'StdMaintGroupDiscription',
EMSI.Description as 'StdMaintItemDescription',
case EMSH.Basis
when 'F' then 'Annual Date of ' +
		case len(FixedDateMonth) when 1 then '0' + CAST(FixedDateMonth AS varchar(1))  else CAST(FixedDateMonth AS varchar(2)) end + '/' +
		case len(FixedDateDay) when 1 then '0' + CAST(FixedDateDay AS varchar(1))  else CAST(FixedDateDay AS varchar(2)) end
when 'H' then 'Hours - every ' + cast(EMSH.Interval as Varchar)
when 'G' then 'Gallons - every ' + cast(EMSH.Interval as Varchar)
when 'M' then 'Miles - every ' + cast(EMSH.Interval as Varchar)
else EMSH.Basis end as 'BasisDesc'
FROM   dbo.bEMSH EMSH 
join bEMSI  EMSI 
      ON EMSH.EMCo=EMSI.EMCo 
      AND EMSH.Equipment=EMSI.Equipment 
      AND EMSH.StdMaintGroup=EMSI.StdMaintGroup
Join bEMCO With (NoLock) on bEMCO.EMCo = EMSI.EMCo


GO
GRANT SELECT ON  [dbo].[viDim_EMStdMaintGroup] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMStdMaintGroup] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMStdMaintGroup] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMStdMaintGroup] TO [public]
GRANT SELECT ON  [dbo].[viDim_EMStdMaintGroup] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_EMStdMaintGroup] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_EMStdMaintGroup] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_EMStdMaintGroup] TO [Viewpoint]
GO
