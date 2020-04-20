
using Microsoft.VisualBasic;
  
namespace VPLookup.UI
{

  

    public interface IDatePagination {

#region Interface Properties
        
        System.Web.UI.WebControls.LinkButton Day {get;}
                
        System.Web.UI.WebControls.Literal Day1 {get;}
                
        System.Web.UI.WebControls.LinkButton Month {get;}
                
        System.Web.UI.WebControls.Literal Month1 {get;}
                
        IThemeButton NextInterval {get;}
                
        IThemeButton NextPageInterval {get;}
                
        System.Web.UI.WebControls.Literal PageTitle {get;}
                
        IThemeButton PreviousInterval {get;}
                
        IThemeButton PreviousPageInterval {get;}
                
        System.Web.UI.WebControls.LinkButton Quarter {get;}
                
        System.Web.UI.WebControls.Literal Quarter1 {get;}
                
        System.Web.UI.WebControls.Literal StartDate1 {get;}
                
        System.Web.UI.WebControls.LinkButton Week {get;}
                
        System.Web.UI.WebControls.Literal Week1 {get;}
                
        System.Web.UI.WebControls.LinkButton Year {get;}
                
        System.Web.UI.WebControls.Literal Year1 {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
                             
      string Interval {get; set;}
      void ProcessPreviousPeriod();
      void ProcessPreviousPagePeriod(int periodsShown);
      void ProcessNextPeriod();
      void ProcessNextPagePeriod(int periodsShown);
      void SetPeriodsShown(int periodsShown);
      string FirstStartDate {get; set;}
        

#endregion

    }

  
}
  