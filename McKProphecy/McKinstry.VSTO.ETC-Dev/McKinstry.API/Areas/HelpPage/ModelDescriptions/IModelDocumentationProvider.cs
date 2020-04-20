using System;
using System.Reflection;
using McKinstry.Data.Models.Viewpoint;

namespace McKinstry.WebAPI.Areas.HelpPage.ModelDescriptions
{
    public interface IModelDocumentationProvider
    {
        string GetDocumentation(MemberInfo member);

        string GetDocumentation(Type type);
    }
}