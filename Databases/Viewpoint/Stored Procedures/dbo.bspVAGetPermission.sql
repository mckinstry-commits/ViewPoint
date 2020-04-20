SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVAGetPermission    Script Date: 8/28/99 9:33:44 AM ******/
CREATE PROC [dbo].[bspVAGetPermission] 
   /**************************************************************
   * Object:  Stored Procedure dbo.bspVAGetPermission
   ***************************************************************
   * displays permissions for a given object, used in VA view generator 
   * the heirarchy of permissions are user, group, public 
   * input:  @object  (view/form/sp)
   * output: grouptype (0,1,2), ptype ('grant','revoke'), action ('select', 'update'),
   *         username
   * 2/25/96 JRE 
   * Modified by:  LM  4/21/99 - made compatible with SQL 7.0
					AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
   *
   * USED BY
   *   VA
   *   HQUD  add user defined Field SAE 6/12/97
   **************************************************************/
(
  @vname varchar(30) = NULL
)
AS 
SET nocount ON 
BEGIN
    SELECT  gtype = CASE WHEN u.[uid] = 0 THEN 0  /* public */
                         WHEN u.[uid] > 16000 THEN 1  /* group */
                         ELSE 2  /*user */
                    END,
            ptype = CASE WHEN p.protecttype = 205 THEN 'grant'
                         WHEN p.protecttype = 206 THEN 'revoke'
                         ELSE 'unknown '
                    END,
            name = CONVERT(varchar(30), v.name),
            username = CONVERT(varchar(30), USER_NAME(p.[uid]))
    FROM    sysprotects p
				JOIN master.dbo.spt_values v ON	 p.[action] = v.number
				JOIN sysusers u ON u.[uid] = p.[uid]
    WHERE   p.id = OBJECT_ID(@vname)
            AND v.[type] = 'T'
    ORDER BY gtype
END

GO
GRANT EXECUTE ON  [dbo].[bspVAGetPermission] TO [public]
GO
