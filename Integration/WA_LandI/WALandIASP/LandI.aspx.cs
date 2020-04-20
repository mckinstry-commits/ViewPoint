using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WALandIASP
{
    public partial class WebForm1 : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            Image1.ImageUrl = "~/MCK.png";

        }

        protected void lnkStart_Click(object sender, EventArgs e)
        {
            startDatePicker.Visible = true;
        }

        protected void lnkEnd_Click(object sender, EventArgs e)
        {
            endDatePicker.Visible = true;
        }

        protected void startDatePicker_SelectionChanged(object sender, EventArgs e)
        {
            txtStartDt.Text = startDatePicker.SelectedDate.ToString("MM/dd/yyyy", System.Globalization.CultureInfo.InvariantCulture);
           
            startDatePicker.Visible = false;
        }

        protected void endDatePicker_SelectionChanged(object sender, EventArgs e)
        {
            txtEndDt.Text = endDatePicker.SelectedDate.ToString("MM/dd/yyyy", System.Globalization.CultureInfo.InvariantCulture);
            endDatePicker.Visible = false;

        }

        protected void btnCreateXML_Click(object sender, EventArgs e)
        {
            
            string res = txtBoxIntent.Text;
            string incIntent = IncludeIntents.SelectedItem.Value;

        //    MakeXML.XMLMakerWS xmlmaker = new MakeXML.XMLMakerWS();
            string intentID, startDt, endDt;
            intentID = this.txtBoxIntent.Text;
            startDt = this.txtStartDt.Text;
            endDt = this.txtEndDt.Text;
            //  res = xmlmaker.LandIFileMaker(intentID, startDt, endDt, incIntent);

            XML_Maker.XMLMakerWS landi = new XML_Maker.XMLMakerWS();
            res = landi.LandI(intentID, startDt, endDt, incIntent);



        }

        protected void startDatePicker_DayRender(object sender, DayRenderEventArgs e)
        {
            if (e.Day.Date.DayOfWeek == DayOfWeek.Monday)
            {
                e.Day.IsSelectable = false;
            }
            if (e.Day.Date.DayOfWeek == DayOfWeek.Tuesday)
            {
                e.Day.IsSelectable = false;
            }
            if (e.Day.Date.DayOfWeek == DayOfWeek.Wednesday)
            {
                e.Day.IsSelectable = false;
            }
            if (e.Day.Date.DayOfWeek == DayOfWeek.Thursday)
            {
                e.Day.IsSelectable = false;
            }
            if (e.Day.Date.DayOfWeek == DayOfWeek.Friday)
            {
                e.Day.IsSelectable = false;
            }
            if (e.Day.Date.DayOfWeek == DayOfWeek.Saturday)
            {
                e.Day.IsSelectable = false;
            }
        }

        protected void endDatePicker_DayRender(object sender, DayRenderEventArgs e)
        {
            if (e.Day.Date.DayOfWeek == DayOfWeek.Monday)
            {
                e.Day.IsSelectable = false;
            }
            if (e.Day.Date.DayOfWeek == DayOfWeek.Tuesday)
            {
                e.Day.IsSelectable = false;
            }
            if (e.Day.Date.DayOfWeek == DayOfWeek.Wednesday)
            {
                e.Day.IsSelectable = false;
            }
            if (e.Day.Date.DayOfWeek == DayOfWeek.Thursday)
            {
                e.Day.IsSelectable = false;
            }
            if (e.Day.Date.DayOfWeek == DayOfWeek.Friday)
            {
                e.Day.IsSelectable = false;
            }
            if (e.Day.Date.DayOfWeek == DayOfWeek.Saturday)
            {
                e.Day.IsSelectable = false;
            }
        }
    }
}