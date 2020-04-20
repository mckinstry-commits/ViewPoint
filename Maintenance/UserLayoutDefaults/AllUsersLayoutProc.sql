Create proc [dbo].[mckMasterLayoutResetAll] 
 @ReturnValue int,
      @ReturnMessage varchar(255) OUTPUT
as

-- deletes user settings for JC Cost Projections
begin
delete bJCUO 
--select *
from bJCUO j
join vDDUP u on j.UserName = u.VPUserName
where u.udApplyMaster = 'Y' and u.VPUserName <> 'PML1'
end

 -- Applies JC Cost Projection layouts to user from a master user login
begin
INSERT INTO bJCUO
        ( JCCo ,
          Form ,
          UserName ,
          ChangedOnly ,
          ItemUnitsOnly ,
          PhaseUnitsOnly ,
          ShowLinkedCT ,
          ShowFutureCO ,
          RemainUnits ,
          RemainHours ,
          RemainCosts ,
          OpenForm ,
          PhaseOption ,
          BegPhase ,
          EndPhase ,
          CostTypeOption ,
          SelectedCostTypes ,
          VisibleColumns ,
          ColumnOrder ,
          ThruPriorMonth ,
          NoLinkedCT ,
          ProjMethod ,
          Production ,
          ProjInitOption ,
          ProjWriteOverPlug ,
          RevProjFilterBegItem ,
          RevProjFilterEndItem ,
          RevProjFilterBillType ,
          RevProjCalcWriteOverPlug ,
          RevProjCalcMethod ,
          RevProjCalcMethodMarkup ,
          RevProjCalcBillType ,
          RevProjCalcBegContract ,
          RevProjCalcEndContract ,
          RevProjCalcBegItem ,
          RevProjCalcEndItem ,
          ProjInactivePhases ,
          OrderBy ,
          CycleMode ,
          RevProjFilterBegDept ,
          RevProjFilterEndDept ,
          RevProjCalcBegDept ,
          RevProjCalcEndDept ,
          ColumnWidth  )

select distinct HQCo ,
          Form ,
          a.VPUserName,
          ChangedOnly ,
          ItemUnitsOnly ,
          PhaseUnitsOnly ,
          ShowLinkedCT ,
          ShowFutureCO ,
          RemainUnits ,
          RemainHours ,
          RemainCosts ,
          OpenForm ,
          PhaseOption ,
          BegPhase ,
          EndPhase ,
          CostTypeOption ,
          SelectedCostTypes ,
          VisibleColumns ,
          ColumnOrder ,
          ThruPriorMonth ,
          NoLinkedCT ,
          ProjMethod ,
          Production ,
          ProjInitOption ,
          ProjWriteOverPlug ,
          RevProjFilterBegItem ,
          RevProjFilterEndItem ,
          RevProjFilterBillType ,
          RevProjCalcWriteOverPlug ,
          RevProjCalcMethod ,
          RevProjCalcMethodMarkup ,
          RevProjCalcBillType ,
          RevProjCalcBegContract ,
          RevProjCalcEndContract ,
          RevProjCalcBegItem ,
          RevProjCalcEndItem ,
          ProjInactivePhases ,
          OrderBy ,
          CycleMode ,
          RevProjFilterBegDept ,
          RevProjFilterEndDept ,
          RevProjCalcBegDept ,
          RevProjCalcEndDept ,
          ColumnWidth  from bJCUO u CROSS JOIN bHQCO 
          cross join (Select VPUserName from vDDUP where udApplyMaster = 'Y') as a
          WHERE u.UserName ='PML1' and JCCo = 101
end



-- deletes user specific information on defaulting to grid/info tab and if a filter bar is to show
begin
delete vDDFU 
--select * 
from vDDFU j
join vDDUP u on j.VPUserName = u.VPUserName
where u.udApplyMaster = 'Y' and u.VPUserName <> 'USER1'
end

-- Applies defaulting to grid/info tab and if a filter bar is to show from master user login  settings
begin 
INSERT INTO vDDFU
        ( VPUserName ,
          Form ,
          DefaultTabPage ,
          FormPosition ,
          LastAccessed ,
          GridRowHeight ,
          SplitPosition ,
          Options ,
          FilterOption ,
          LimitRecords ,
          DefaultAttachmentTypeID ,
          OpenAttachmentViewer
        )
        select
          a.VPUserName ,
          Form ,
          DefaultTabPage ,
          FormPosition ,
          LastAccessed ,
          GridRowHeight ,
          SplitPosition ,
          Options ,
          FilterOption ,
          LimitRecords ,
          DefaultAttachmentTypeID ,
          OpenAttachmentViewer
          from vDDFU u
           cross join (Select VPUserName from DDUP where udApplyMaster = 'Y') as a
          where u.VPUserName = 'USER1'
end












-- deletes user specific column arrangements/widths, input skips and defaults
begin
delete vDDUI 
--select *
from vDDUI j
join vDDUP u on j.VPUserName = u.VPUserName
where u.udApplyMaster = 'Y' and u.VPUserName <> 'USER1'
end

-- Applies user specific column arrangements/widths, input skips and defaults based on master user login settings
begin   
insert into vDDUI

		( VPUserName ,
          Form ,
          Seq ,
          DefaultType ,
          DefaultValue ,
          InputSkip ,
          InputReq ,
          GridCol ,
          ColWidth ,
          ShowGrid ,
          ShowForm ,
          DescriptionColWidth ,
          ShowDesc
        )

          select a.VPUserName,
		 vDDUI.Form
		, vDDUI.Seq
		, vDDUI.DefaultType
                , vDDUI.DefaultValue
                , vDDUI.InputSkip
                , vDDUI.InputReq
                , vDDUI.GridCol
                , vDDUI.ColWidth
                , vDDUI.ShowGrid
                , vDDUI.ShowForm
                , vDDUI.DescriptionColWidth
                , vDDUI.ShowDesc
          from vDDUI 
          	   join DDFIShared on vDDUI.Form = DDFIShared.Form and vDDUI.Seq = DDFIShared.Seq
           cross join (Select VPUserName from DDUP where udApplyMaster = 'Y') as a
          where vDDUI.VPUserName = 'USER1'              
End








BEGIN
      if @ReturnValue = 0 
      Begin
            SET @ReturnMessage = 'Master Layout Assigned to all checked users'
      End
      Else
      Begin
            SET @ReturnMessage = 'This is a failure message'
      End
      
      return @ReturnValue
END;






GO



