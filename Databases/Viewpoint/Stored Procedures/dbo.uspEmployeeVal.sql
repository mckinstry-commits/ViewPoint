USE [Viewpoint]
GO
/****** Object:  StoredProcedure [dbo].[uspEmployeeVal]    Script Date: 8/13/2013 11:08:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[uspEmployeeVal] /** User Defined Validation Procedure **/
(@@PRCo varchar(100), @@Employee varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [PREHName] with (nolock) where   @@PRCo = [PRCo] And  @@Employee = [Employee] )
begin
select @msg = isnull([FullName],@msg) from [PREHName] with (nolock) where   @@PRCo = [PRCo] And  @@Employee = [Employee] 
end
else
begin
select @msg = 'Employee does not exist', @rcode = 1
goto spexit
end

spexit:

return @rcode