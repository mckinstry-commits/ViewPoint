SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		AL vspDDUPCopy5xUDColumnsTo6x
-- Create date: 7/10/09
-- Description:	Copies ud columns from bDDUP to vDDUP
-- =============================================
CREATE PROCEDURE [dbo].[vspDDUPCopy5xUDColumnsTo6x]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



--Modify DDUP with UD columns------------------------------
declare @name as varchar(30), @sqlcmd as varchar(250), @formname as varchar(30),    @tabnbr tinyint,                      --  2
            @tablename as varchar(30),
            @viewname as varchar(30),
            @columnname as varchar(30),
            @usedatatype as bYN,
            @inputtype as tinyint,
            @inputlen as int,
            @sysdatatype as varchar(30),
            @inputmask as varchar(30),
            @prec as int,
            @labeltext as bDesc,
            @columnhdrtext as bDesc,
            @statustext as varchar(256),
            @required as bYN ,
            @desc as bDesc ,
            @controltype as tinyint,
            @combotype as varchar(20) ,
            @vallevel as tinyint ,
            @valproc as varchar(60) ,
            @valparams as varchar(256) ,
            @valmin as varchar(20) ,
            @valmax as varchar(20) ,
            @valexpr as varchar(256) ,
            @valexprerror as varchar(256) ,
            @defaulttype as tinyint ,
            @defaultvalue as varchar(256) ,
            @activelookup as bYN ,
            @msg as varchar(255),
            @errmsg varchar(128),
            @rcode integer
            
declare udfields cursor for 
Select  distinct Form, Tab, 'vDDUP' as [Table], 'DDUP' as [View], ColumnName, case isnull(Datatype,'') when '' then 'N' else 'Y' end as UseDataType, InputType,
InputLength, Datatype, InputMask, Prec, Label, GridColHeading, StatusText, Req, [Description],
ControlType, ComboType, ValLevel, ValProc, ValParams, MinValue, MaxValue, ValExpression, ValExpError, DefaultType, 
DefaultValue, ActiveLookup from DDFIc
Where Form = 'VADDUP'

if exists(Select  distinct Form, Tab, 'vDDUP' as [Table], 'DDUP' as [View], ColumnName, case isnull(Datatype,'') when '' then 'N' else 'Y' end as UseDataType, InputType,
InputLength, Datatype, InputMask, Prec, Label, GridColHeading, StatusText, Req, [Description],
ControlType, ComboType, ValLevel, ValProc, ValParams, MinValue, MaxValue, ValExpression, ValExpError, DefaultType, 
DefaultValue, ActiveLookup from DDFIc
Where Form = 'VADDUP')

				begin 
				INSERT into  DDFTc
				([Form],[Tab],[Title],[GridForm],[LoadSeq],[IsVisible])
				Values ('VADDUP', 100, 'Memo', null, 100, null)
				end

open udfields


Fetch next from udfields 
into  @formname,  @tabnbr,    @tablename, @viewname, @columnname, @usedatatype,
@inputtype, @inputlen,  @sysdatatype, @inputmask,     @prec,      @labeltext, @columnhdrtext,
@statustext,      @required,  @desc,      @controltype,     @combotype, @vallevel,  @valproc,
@valparams, @valmin,    @valmax,    @valexpr,   @valexprerror,    @defaulttype,      @defaultvalue,
@activelookup 

while @@fetch_status = 0
begin

begin try

Delete from DDFIc where Form = @formname and ColumnName = @columnname

exec dbo.vspHQUDAdd @formname,      @tabnbr,    @tablename, @viewname, @columnname,      @usedatatype,
@inputtype, @inputlen,  @sysdatatype, @inputmask,     @prec,      @labeltext, @columnhdrtext,
@statustext,      @required,  @desc,      @controltype,     @combotype, @vallevel,  @valproc,
@valparams, @valmin,    @valmax,    @valexpr,   @valexprerror,    @defaulttype,      @defaultvalue,
@activelookup, @msg OUTPUT


declare @updatestring as varchar(1000)

select @updatestring = 'update vDDUP set vDDUP.' + @columnname + ' =  bDDUP.' + @columnname + ' From 
vDDUP vDDUP join  bDDUP bDDUP on vDDUP.VPUserName = bDDUP.name'

exec (@updatestring)

end try
begin catch
      select @errmsg = 'Error converting UD fields (vDDUP).', @rcode = 1
      exec dbo.vspV6ConvLogSQLErrors @errmsg
end catch
 
 Fetch next from udfields 
into  @formname,  @tabnbr,    @tablename, @viewname, @columnname, @usedatatype,
@inputtype, @inputlen,  @sysdatatype, @inputmask,     @prec,      @labeltext, @columnhdrtext,
@statustext,      @required,  @desc,      @controltype,     @combotype, @vallevel,  @valproc,
@valparams, @valmin,    @valmax,    @valexpr,   @valexprerror,    @defaulttype,      @defaultvalue,
@activelookup 

End
Close udfields
Deallocate udfields

end
vspexit: 

return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDUPCopy5xUDColumnsTo6x] TO [public]
GO
