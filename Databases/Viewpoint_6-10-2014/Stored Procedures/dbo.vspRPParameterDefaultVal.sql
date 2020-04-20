SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPParameterDefaultVal] 
/***********************************************
* Created: GG 01/19/07
* Modified: GG 07/02/07 - added parameter default types
*			AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function.
*
* Used to validate report parameter default values assigned
* to a form.
*
* Inputs:
*	@form			Form name, 'X' = no form
*	@reportid		Report ID#
*	@param			Report Parameter
*	@defaulttype	Default Type
*	@default		Parameter default value
* 
************************************************/
    (
      @form VARCHAR(30) = NULL,
      @reportid INT = NULL,
      @param VARCHAR(30) = NULL,
      @defaulttype INT = NULL,
      @default VARCHAR(60) = NULL,
      @msg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
    DECLARE @rcode INT,
        @datatype VARCHAR(30),
        @inputtype TINYINT,
        @char INT,
        @tmp VARCHAR(60)
    SELECT  @rcode = 0

-- get Report Parameter info
    SELECT  @datatype = Datatype,
            @inputtype = InputType
    FROM    dbo.RPRPShared (NOLOCK)
    WHERE   ReportID = @reportid
            AND ParameterName = @param
    IF @@rowcount = 0 
        BEGIN
            SELECT  @msg = 'Invalid Report Parameter!',
                    @rcode = 1
            RETURN @rcode
        END
-- Input Type comes from Datatype if specified on Report Parameter
    IF @datatype IS NOT NULL 
        BEGIN
            SELECT  @inputtype = InputType
            FROM    dbo.DDDTShared (NOLOCK)
            WHERE   Datatype = @datatype
            IF @@rowcount = 0 
                BEGIN
                    SELECT  @msg = 'Invalid Datatype',
                            @rcode = 1
                    RETURN @rcode
                END
        END
	
-- check for Default Type and Value consistency
    IF @defaulttype = 0		-- literal fixed value
        BEGIN
            IF @default IS NOT NULL 
                BEGIN
                    IF @inputtype IN ( 1, 6 )
                        AND ISNUMERIC(@default) = 0 	-- numeric, string to numeric
                        BEGIN
                            SELECT  @msg = 'Default value must be numeric.',
                                    @rcode = 1
                            RETURN @rcode
                        END
                    IF @inputtype = 2
                        AND ISDATE(@default) = 0		-- date
                        BEGIN
                            SELECT  @msg = 'Default value must be a valid date.',
                                    @rcode = 1
                            RETURN @rcode
                        END
                    IF @inputtype = 3			-- month
                        BEGIN
                            SELECT  @char = CHARINDEX('/', @default)
                            IF @char = 0 
                                BEGIN
                                    SELECT  @msg = 'Default value must be a valid month.',
                                            @rcode = 1
                                    RETURN @rcode
                                END
                            ELSE 
                                BEGIN
                                    SELECT  @tmp = SUBSTRING(@default, 1,
                                                             @char - 1)
                                            + '/01' + SUBSTRING(@default,
                                                              @char,
                                                              LEN(@default))
                                    IF ISDATE(@tmp) = 0 
                                        BEGIN
                                            SELECT  @msg = 'Default value must be a valid month.',
                                                    @rcode = 1
                                            RETURN @rcode
                                        END
                                END
                        END
                END
        END	
    IF @defaulttype = 1		-- current date (+/-)
        BEGIN
            IF SUBSTRING(ISNULL(@default, ''), 1, 2) <> '%D' 
                BEGIN
                    SELECT  @msg = 'Date defaults must begin with ''%D''.',
                            @rcode = 1
                    RETURN @rcode
                END
            IF LEN(@default) > 2 
                BEGIN
                    IF SUBSTRING(@default, 3, 1) NOT IN ( '+', '-' )
                        OR LEN(@default) < 4
                        OR ISNUMERIC(SUBSTRING(@default, 4, LEN(@default) - 3)) = 0 
                        SELECT  @msg = 'Use + or - followed by a number to indicate number of days from current date.',
                                @rcode = 1
                    RETURN @rcode
                END
        END	
    IF @defaulttype = 2		-- current month (+/-)
        BEGIN
            IF SUBSTRING(ISNULL(@default, ''), 1, 2) <> '%M' 
                BEGIN
                    SELECT  @msg = 'Month defaults must begin with ''%M''.',
                            @rcode = 1
                    RETURN @rcode
                END
            IF LEN(@default) > 2 
                BEGIN
                    IF SUBSTRING(@default, 3, 1) NOT IN ( '+', '-' )
                        OR LEN(@default) < 4
                        OR ISNUMERIC(SUBSTRING(@default, 4, LEN(@default) - 3)) = 0 
                        SELECT  @msg = 'Use + or - followed by a number to indicate number of months from current date.',
                                @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 3		-- report parameter
        BEGIN
            IF SUBSTRING(ISNULL(@default, ''), 1, 3) <> '%RP' 
                BEGIN
                    SELECT  @msg = 'Defaults based on other Report Parameters must begin with ''%RP''.',
                            @rcode = 1
                    RETURN @rcode
                END
            IF LEN(@default) < 4 
                BEGIN
                    SELECT  @msg = 'A Report Parameter must be included as part of the default value.',
                            @rcode = 1
                    RETURN @rcode
                END
            IF NOT EXISTS ( SELECT TOP 1
                                    1
                            FROM    dbo.RPRPShared (NOLOCK)
                            WHERE   ReportID = @reportid
                                    AND ParameterName = SUBSTRING(@default, 4,
                                                              LEN(@default)
                                                              - 3) ) 
                BEGIN
                    SELECT  @msg = 'Invalid Report Parameter.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 4		-- form input
        BEGIN
            IF SUBSTRING(ISNULL(@default, ''), 1, 3) <> '%FI' 
                BEGIN
                    SELECT  @msg = 'Defaults based on Form Inputs must begin with ''%FI''.',
                            @rcode = 1
                    RETURN @rcode
                END
            IF LEN(@default) < 4 
                BEGIN
                    SELECT  @msg = 'A Form Input # must be included as part of the default value.',
                            @rcode = 1
                    RETURN @rcode
                END
            IF @form = 'X' 
                BEGIN
                    SELECT  @msg = 'Missing Form.',
                            @rcode = 1
                    RETURN @rcode
                END
            SELECT  @msg = Description
				-- use inline table functions for perf
            FROM    dbo.vfDDFIShared(@form) 
            WHERE   Seq = SUBSTRING(@default, 4, LEN(@default) - 3)
            IF @@rowcount = 0 
                BEGIN
                    SELECT  @msg = 'Invalid Form Input #.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 5		-- active Company
        BEGIN
            IF ISNULL(@default, '') <> '%C' 
                BEGIN
                    SELECT  @msg = 'Use ''%C'' to default active Company #.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 6		-- active Project
        BEGIN
            IF ISNULL(@default, '') <> '%Project' 
                BEGIN
                    SELECT  @msg = 'Use ''%Project'' to default active PM Project.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 7		-- active Job
        BEGIN
            IF ISNULL(@default, '') <> '%Job' 
                BEGIN
                    SELECT  @msg = 'Use ''%Job'' to default active JC Job.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 8		-- active Contract
        BEGIN
            IF ISNULL(@default, '') <> '%Contract' 
                BEGIN
                    SELECT  @msg = 'Use ''%Contract'' to default active JC Contract.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 9		-- active PR Group
        BEGIN
            IF ISNULL(@default, '') <> '%PRGroup' 
                BEGIN
                    SELECT  @msg = 'Use ''%PRGroup'' to default active PR Group.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 10		-- active PR Ending Date
        BEGIN
            IF ISNULL(@default, '') <> '%PREndDate' 
                BEGIN
                    SELECT  @msg = 'Use ''%PREndDate'' to default active PR Ending Date.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 11		-- active JB Progress Bill Mth
        BEGIN
            IF ISNULL(@default, '') <> '%JBProgMth' 
                BEGIN
                    SELECT  @msg = 'Use ''%JBProgMth'' to default active JB Progress Bill Month.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 12		-- active JB Progress Bill#
        BEGIN
            IF ISNULL(@default, '') <> '%JBProgBill' 
                BEGIN
                    SELECT  @msg = 'Use ''%JBProgBill'' to default active JB Progress Bill#.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 13		-- active JB T&M Bill Mth
        BEGIN
            IF ISNULL(@default, '') <> '%JBTMMth' 
                BEGIN
                    SELECT  @msg = 'Use ''%JBTMMth'' to default active JB T&M Bill Month.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 14		-- active JB T&M Bill#
        BEGIN
            IF ISNULL(@default, '') <> '%JBTMBill' 
                BEGIN
                    SELECT  @msg = 'Use ''%JBTMBill'' to default active JB T&M Bill#.',
                            @rcode = 1
                    RETURN @rcode
                END
        END
    IF @defaulttype = 15		-- Report Attachment Channel
        BEGIN
            IF ISNULL(@default, '') <> '%RAC' 
                BEGIN
                    SELECT  @msg = 'Use ''%RAC'' to default the active report channel used when printing attachments with the report.',
                            @rcode = 1
                    RETURN @rcode
                END
        END

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRPParameterDefaultVal] TO [public]
GO
