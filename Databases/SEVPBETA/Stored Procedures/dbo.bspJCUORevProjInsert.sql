SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************************/
CREATE PROC [dbo].[bspJCUORevProjInsert]
/***********************************************************
* CREATED BY	: DANF 03/4/2005
* MODIFIED BY	: AMR - Issue TK-07089, Fixing performance issue by using an inline table function.
*
*
*
* USAGE:
*  Inserts the user options for revenue projections into bJCUO
*
*
* INPUT PARAMETERS
*	JCCo		JC Company
*	Form		JC Form Name
*	UserName	VP UserName
*
* OUTPUT PARAMETERS
*   @msg

* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
    (
      @jcco bCompany,
      @form VARCHAR(30),
      @username bVPUserName,
      @RevProjFilterBegItem bContractItem,
      @RevProjFilterEndItem bContractItem,
      @RevProjFilterBillType CHAR(1),
      @RevProjCalcWriteOverPlug CHAR(1),
      @RevProjCalcMethod CHAR(1),
      @RevProjCalcMethodMarkup bPct,
      @RevProjCalcBillType CHAR(1),
      @RevProjCalcBegContract bContract,
      @RevProjCalcEndContract bContract,
      @RevProjCalcBegItem bContractItem,
      @RevProjCalcEndItem bContractItem,
      @msg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
   
    DECLARE @rcode INTEGER,
        @jcco_projmethod CHAR(1),
        @changedonly bYN,
        @itemunitsonly bYN,
        @phaseunitsonly bYN,
        @showlinkedct bYN,
        @showfutureco bYN,
        @remainunits bYN,
        @remainhours bYN,
        @remaincosts bYN,
        @openform bYN,
        @phaseoption CHAR(1),
        @begphase bPhase,
        @endphase bPhase,
        @costtypeoption CHAR(1),
        @selectedcosttypes VARCHAR(1000),
        @visiblecolumns VARCHAR(1000),
        @columnorder VARCHAR(1000),
        @thrupriormonth bYN,
        @nolinkedct bYN,
        @projmethod CHAR(1),
        @production CHAR(1),
        @writeoverplug CHAR(1),
        @initoption CHAR(1)

    SELECT  @rcode = 0

    IF ISNULL(@changedonly, '') NOT IN ( 'Y', 'N' ) 
        SET @changedonly = 'N'
    IF ISNULL(@itemunitsonly, '') NOT IN ( 'Y', 'N' ) 
        SET @itemunitsonly = 'N'
    IF ISNULL(@phaseunitsonly, '') NOT IN ( 'Y', 'N' ) 
        SET @phaseunitsonly = 'N'
    IF ISNULL(@showlinkedct, '') NOT IN ( 'Y', 'N' ) 
        SET @showlinkedct = 'N'
    IF ISNULL(@showfutureco, '') NOT IN ( 'Y', 'N' ) 
        SET @showfutureco = 'N'
    IF ISNULL(@remainunits, '') NOT IN ( 'Y', 'N' ) 
        SET @remainunits = 'N'
    IF ISNULL(@remainhours, '') NOT IN ( 'Y', 'N' ) 
        SET @remainhours = 'N'
    IF ISNULL(@remaincosts, '') NOT IN ( 'Y', 'N' ) 
        SET @remaincosts = 'N'
    IF ISNULL(@openform, '') NOT IN ( 'Y', 'N' ) 
        SET @openform = 'N'
    IF ISNULL(@phaseoption, '') NOT IN ( '0', '1' ) 
        SET @phaseoption = '0'
    IF ISNULL(@costtypeoption, '') NOT IN ( '0', '1' ) 
        SET @costtypeoption = '0'
    IF ISNULL(@thrupriormonth, '') NOT IN ( 'Y', 'N' ) 
        SET @thrupriormonth = 'N'
    IF ISNULL(@nolinkedct, '') NOT IN ( 'Y', 'N' ) 
        SET @nolinkedct = 'N'
    IF ISNULL(@projmethod, '') NOT IN ( '1', '2' ) 
        SET @projmethod = '1'
    IF ISNULL(@production, '') NOT IN ( '0', '1', '2' ) 
        SET @production = '0'
    IF ISNULL(@writeoverplug, '') NOT IN ( '0', '1', '2' ) 
        SET @writeoverplug = '1'
    IF ISNULL(@initoption, '') NOT IN ( '0', '1' ) 
        SET @initoption = '1'
   
   -- validate JCCo
    SELECT  @jcco_projmethod = ProjMethod
    FROM    dbo.bJCCO WITH ( NOLOCK )
    WHERE   JCCo = @jcco
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Invalid JC Company.',
                    @rcode = 1
            RETURN @rcode
        END
   
   -- validate form
               -- use an inline table function for performance
    IF NOT EXISTS ( SELECT  Form
                    FROM    dbo.vfDDFIShared(@form) ) 
        BEGIN
            SELECT  @msg = 'Invalid JC Form.',
                    @rcode = 1
           RETURN @rcode
        END
   
   -- use company projection method if none
    IF ISNULL(@projmethod, '') = '' 
        SET @projmethod = ISNULL(@jcco_projmethod, '1')
   
   -- insert projection user options record
    INSERT  dbo.bJCUO
            ( JCCo,
              Form,
              UserName,
              ChangedOnly,
              ItemUnitsOnly,
              PhaseUnitsOnly,
              ShowLinkedCT,
              ShowFutureCO,
              RemainUnits,
              RemainHours,
              RemainCosts,
              OpenForm,
              PhaseOption,
              BegPhase,
              EndPhase,
              CostTypeOption,
              SelectedCostTypes,
              VisibleColumns,
              ColumnOrder,
              ThruPriorMonth,
              NoLinkedCT,
              ProjMethod,
              Production,
              ProjInitOption,
              ProjWriteOverPlug,
              RevProjFilterBegItem,
              RevProjFilterEndItem,
              RevProjFilterBillType,
              RevProjCalcWriteOverPlug,
              RevProjCalcMethod,
              RevProjCalcMethodMarkup,
              RevProjCalcBillType,
              RevProjCalcBegContract,
              RevProjCalcEndContract,
              RevProjCalcBegItem,
              RevProjCalcEndItem
            )
            SELECT  @jcco,
                    @form,
                    @username,
                    @changedonly,
                    @itemunitsonly,
                    @phaseunitsonly,
                    @showlinkedct,
                    @showfutureco,
                    @remainunits,
                    @remainhours,
                    @remaincosts,
                    @openform,
                    @phaseoption,
                    @begphase,
                    @endphase,
                    @costtypeoption,
                    @selectedcosttypes,
                    @visiblecolumns,
                    @columnorder,
                    @thrupriormonth,
                    @nolinkedct,
                    @projmethod,
                    @production,
                    @initoption,
                    @writeoverplug,
                    @RevProjFilterBegItem,
                    @RevProjFilterEndItem,
                    @RevProjFilterBillType,
                    @RevProjCalcWriteOverPlug,
                    @RevProjCalcMethod,
                    @RevProjCalcMethodMarkup,
                    @RevProjCalcBillType,
                    @RevProjCalcBegContract,
                    @RevProjCalcEndContract,
                    @RevProjCalcBegItem,
                    @RevProjCalcEndItem
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Unable to insert default user options into JCUO.',
                    @rcode = 1
           RETURN @rcode
        END
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCUORevProjInsert] TO [public]
GO
