SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*  Changes to stored procedure required when updating between Viewpoint 5.10.1 and Viewpoint 6.0
    Use RPRTShared for RPRT
    Use ReportID to link RPTP and DDTH
    Use ViewName to link TableName in previous views.
    NF 12/13/05  This Stored Procedure is used by the Views and Reports by View Type Drilldown report  */
  
  
  
CREATE        proc [dbo].[brptRPInfoByTable] 
	(@Module varchar(10), @BegTitle varchar(40), @EndTitle varchar (40), @ExcludeTypes varchar(40), @Table varchar (30))
   
   as
   
   
   select /*Type=(case when (select distinct Title From RPTP tp Join DDTH th on th.TableName=tp.TableName
                          Where tp.Title=RPTP.Title and th.TableType='Detail')=RPTP.Title then 'Detail' else 'Maint' end),*/
            Module=(case when DDTH.TableType='Detail' then Left(RPTP.ViewName,2)
                      when RF.FieldType='Stored Procedure' then RPRM.Mod --substring(RF.RFTable,5,2)
                      when left(RFTable,3)='brv' or left(RFTable,3)='vrv' then RPRM.Mod --substring(RF.RFTable,4,2)
                      when DDTH.TableType='Maint' then Left(DDTH.TableName,2)
                   else RPRM.Mod end),
           ViewType=(case when DDTH.TableType='Detail' then 'D'
                       when RF.FieldType='Stored Procedure' then 'S'
                       when left(RFTable,3)='brv' or left(RFTable,3)='vrv' then 'V'
                       when DDTH.TableType='Maint' then 'M'
                   else 'Z'
                  end),
         --DetailTypeYN=(case when Detail.ReportID is not null then 'Y' else 'N' end),
         DetailTable=(case when DDTH.TableType='Detail' then RPTP.ViewName end),
         DetailTableDesc=(case when DDTH.TableType='Detail' then DDTH.Description end),
         StoredProc=(case when RF.FieldType='Stored Procedure' then RF.RFTable end),
         ReportView=(case when left(RFTable,3)='brv' or left(RFTable,3)='vrv' then RF.RFTable end),
/*=(case when RPTP.TableName Like 'brpt%' then RPTP.TableName end),*/
         /*PrimMaintTable=(case when RF.FieldType='Tables' and DDTH.TableType='Maint' 
                              then Left(RF.RFTable,4) end ),*/
                        /*=(select substring(rf.ReportText,1,30) From RPRF rf Where rf.Title=RPTP.Title and rf.FieldType='Groups')*/
         RPRT.Title, RPRT.ReportID, RPRT.FileName, RPRT.ReportType, RPRT.ReportDesc, /*SearchCol, SearchColTable,*/
         RPTable=DDTH.TableName, RPTableType=DDTH.TableType, RPTableDesc=DDTH.Description,
         TableIndex=(select top 1 IndexColumns From DDTI Where DDTI.TableName=RPTP.ViewName)
         /*TableNotes=DDTH.Notes*/
  From RPTP with(nolock)
  Join RPRTShared RPRT with(nolock) on RPRT.ReportID=RPTP.ReportID
  Left Outer Join DDTH with(nolock) on DDTH.TableName=RPTP.ViewName --and DDTH.TableType not in ('Audit','Dist')
  --Left Outer Join RPRF on RPRF.Title=RPTP.Title and FieldType='Groups'
  /*Left Outer Join (select distinct tp.ReportID, th.TableName, TableDesc=th.Description From RPTP tp with(nolock) 
                          Join DDTH th with(nolock) on th.TableName=tp.ViewName
                          Where th.TableType = 'Detail') as Detail 
              on Detail.ReportID=RPTP.ReportID*/
  Left Outer Join (Select distinct r.ReportID, r.FieldType, 
                                   RFTable=r.ReportText
                          From RPRF r 
                    where r.FieldType = 'Stored Procedure' 
                          or (r.FieldType='Tables' 
                               and substring(r.ReportText,2,2)='rv')) as RF
              on RF.ReportID=RPTP.ReportID and RF.RFTable=RPTP.ViewName
  Join RPRMShared RPRM on RPRM.ReportID=RPRT.ReportID

   
   Where
     (case when DDTH.TableType='Detail' then Left(RPTP.ViewName,2)
                      when RF.FieldType='Stored Procedure' then RPRM.Mod
                      when left(RFTable,3)='brv' or left(RFTable,3)='vrv' then RPRM.Mod
                      when DDTH.TableType='Maint' then Left(DDTH.TableName,2)
                   else RPRM.Mod end)
       = (case when @Module<>' ' then @Module 
            else (case when DDTH.TableType='Detail' then Left(RPTP.ViewName,2)
                      when RF.FieldType='Stored Procedure' then RPRM.Mod
                      when left(RFTable,3)='brv' or left(RFTable,3)='vrv' then RPRM.Mod
                      when DDTH.TableType='Maint' then Left(DDTH.TableName,2)
                      else RPRM.Mod 
                   end)
            end)
     and RPRT.Title>=@BegTitle and RPRT.Title<=@EndTitle

GO
GRANT EXECUTE ON  [dbo].[brptRPInfoByTable] TO [public]
GO
