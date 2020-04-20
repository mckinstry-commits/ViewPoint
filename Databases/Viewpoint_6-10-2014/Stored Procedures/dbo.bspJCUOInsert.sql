SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE   PROC [dbo].[bspJCUOInsert]
/***********************************************************
* CREATED BY:	GF 02/26/2004
* MODIFIED BY:	TV	23061 added isnulls
*				GF	06/09/2004	- issue #24788 - verify column values are correct
*				GF	03/15/2005	- issue #27183 - added JCUO.ProjInactivePhases
*				GF	09/01/2005	- issue #29675 - use JCCO.ProjMethod if @projmethod is empty
*				CHS 02/27/08	- issues #126235 & #121624
*				GF	03/27/2008	- issue #126993 added 2 columns to bJCUO
*				CHS	07/31/2008	- issue #126238 & #128426
*				CHS	09/15/2008	- issue #126236
*				CHS	10/08/2008	- issue #126236
*				GP 06/01/2009 - Issue 133774 set @projmethod to allow null input
*				CHS 07/27/2009	- issue #134592
*				GF 02/26/2010 - issue #137728 - included CO hours and units
*				GF 10/15/2010 - issue #141731 - added Future Actual Cost column
*				GF 07/16/2011 - TK-06820 added Uncommitted Cost column
*				AMR - 7/25/11 - TK-06411, Fixing performance issue by using an inline table function., Fixing performance issue by using an inline table function.
*
*
* USAGE:
*  Inserts the user options for projections into bJCUO
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
      @projmethod CHAR(1) = NULL,
      @production CHAR(1),
      @writeoverplug CHAR(1),
      @initoption CHAR(1),
      @projinactivephases bYN,
      @orderby CHAR(1),
      @cyclemode bYN,
      @columnwidth VARCHAR(MAX) = NULL,
      @msg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON

    DECLARE @rcode INTEGER,
        @jcco_projmethod CHAR(1)

    SELECT  @rcode = 0

---- validate JCCo
    SELECT  @jcco_projmethod = ProjMethod
    FROM    dbo.bJCCO WITH ( NOLOCK )
    WHERE   JCCo = @jcco
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Invalid JC Company.',
                    @rcode = 1
            GOTO bspexit
        END

---- use company projection method if none
    IF ISNULL(@projmethod, '') = '' 
        SET @projmethod = ISNULL(@jcco_projmethod, '1')

---- validate form
    IF NOT EXISTS ( SELECT  Form
					--use inline table function for perf
                    FROM    dbo.vfDDFIShared(@form )
                     ) 
        BEGIN
            SELECT  @msg = 'Invalid JC Form.',
                    @rcode = 1
            GOTO bspexit
        END

---- check if already exists in JCUO
    IF EXISTS ( SELECT  Form
                FROM    dbo.bJCUO WITH ( NOLOCK )
                WHERE   JCCo = @jcco
                        AND Form = @form
                        AND UserName = @username ) 
        BEGIN
            GOTO bspexit
        END

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
    IF ISNULL(@projinactivephases, '') NOT IN ( 'Y', 'N' ) 
        SET @projinactivephases = 'N'
    IF ISNULL(@orderby, '') NOT IN ( 'C', 'P' ) 
        SET @orderby = 'P'
    IF ISNULL(@cyclemode, '') NOT IN ( 'Y', 'N' ) 
        SET @cyclemode = 'N'

    IF @form = 'JCProjection' 
        BEGIN
		---- #137728
		---- #141731 TK-06820
            SELECT  @visiblecolumns = 'False;True;True;True;False;False;False;False;True;True;True;False;True;True;True;False;False;False;False;False;False;False;False;False;False;False;False;True;True;False;False;False;False;True;False;False;False;False;False;False;False;False;False;False;False;False;False;False'
            SELECT  @columnorder = 'Original Est''d Cost;Curr Est + Incl CO''s;Actual Cost;Projected Cost;P;Over / Under;Future CO Cost;Original Est''d Units;Current Est''d Units;Actual Units;Projected Units;Current Est''d Hours;Original Est''d Hours;Actual Hours;Projected Hours;Original Est''d Unit Cost;Current Est''d Unit Cost;Actual Unit Cost;Projected Unit Cost;Total Cmtd Cost;Total Cmtd Units;Remaining Cmtd Cost;Remaining Cmtd Units;Forecast Cost;Forecast Units;Forecast Hours;Forecast Unit Cost;Actual + Committed Units;Actual + Committed Cost;Remaining Units;Remaining Hours;Remaining Costs;Linked to Cost Type;Contract Item;Notes;Prev Projected Units;Prev Projected Hours;Prev Projected Cost;Prev Projected Unit Cost;% Complete of Units;% Complete of Dollars;Current Estimated Cost;Included CO Amt;Displayed CO''s;Included CO Hours;Included CO Units;Future Actual Cost;Uncommitted Cost;'
		---- #137728
        END

    ELSE 
        BEGIN
            SELECT  @visiblecolumns = NULL
            SELECT  @columnorder = NULL
        END


---- insert projection user options record
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
              ProjInactivePhases,
              OrderBy,
              CycleMode
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
                    @projinactivephases,
                    @orderby,
                    @cyclemode
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Unable to insert default user options into JCUO.',
                    @rcode = 1
            GOTO bspexit
        END



    bspexit:
    IF @rcode <> 0 
        SELECT  @msg = @msg
    RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspJCUOInsert] TO [public]
GO
