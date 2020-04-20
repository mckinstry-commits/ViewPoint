-- created by Brad Worsham 09-01-2013
-- this procedure is applied to a button on VA User Profile
alter proc [dbo].[mckMasterLayoutPerUser] 
@username bVPUserName, @ReturnValue int,
      @ReturnMessage varchar(255) OUTPUT

as

-- deletes user settings for JC Cost Projections
begin
delete from bJCUO 
where UserName = @username and UserName<> 'PML1'
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
          @username,
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
          ColumnWidth  from JCUO CROSS JOIN HQCO WHERE UserName ='PML1'
end





-- deletes user specific information on defaulting to grid/info tab and if a filter bar is to show
begin
delete from vDDFU where VPUserName = @username and VPUserName <> 'USER1'
end

-- Applies defaulting to grid/info tab and if a filter bar is to show from master user login  settings
begin 
INSERT INTO dbo.vDDFU
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
          @username ,
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
          from vDDFU where VPUserName = 'USER1'
end


















-- deletes user specific column arrangements/widths, input skips and defaults
begin
delete from vDDUI where [VPUserName] = @username and VPUserName <> 'USER1'
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

          select @username
		    , vDDUI.Form
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
          join vDDFI on vDDUI.Form = vDDFI.Form and vDDUI.Seq = vDDFI.Seq
          where vDDUI.VPUserName='USER1'                  
End
BEGIN
      if @ReturnValue = 0 
      Begin
            SET @ReturnMessage = 'Master Layout Assigned to specified user'
      End
      Else
      Begin
            SET @ReturnMessage = 'This is a failure message'
      End
      
      return @ReturnValue
END;
GO
