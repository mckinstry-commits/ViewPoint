using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MCK.CraftClass.Viewpoint
{
    public enum ProgressBarDisplayText
    {
        Percentage,
        CustomText
    }

    class MyProgressBar : ProgressBar
    {
        //Property to set to decide whether to print a % or Text
        public ProgressBarDisplayText DisplayStyle { get; set; }

        //Property to hold the custom text
        public String CustomText { get; set; }

        public MyProgressBar()
        {
            //http://msdn.microsoft.com/en-us/library/system.windows.forms.controlstyles.aspx
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint, true);
            SetStyle(ControlStyles.OptimizedDoubleBuffer, true);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Rectangle rect  = ClientRectangle;
            Graphics g      = e.Graphics;
            ProgressBarRenderer.DrawHorizontalBar(g, rect);
            rect.Inflate(-2, -2);

            if (Value > 0)
            {
                // draw the chunks on the progress bar
                Rectangle clip = new Rectangle(rect.X, rect.Y, (int)Math.Round((Value / (double)Maximum) * rect.Width), rect.Height);
                ProgressBarRenderer.DrawHorizontalChunks(g, clip);
            }

            // Set the Display text (Either a % amount or our custom text
            int percent = (int)((Value / (double)Maximum) * 100);
            string text = DisplayStyle == ProgressBarDisplayText.Percentage ? percent.ToString() + '%' : CustomText;

            using (Font f = new Font(FontFamily.GenericSerif, 10))
            {
                //SizeF len = g.MeasureString(text, f);
                // Calculate the location of the text (the middle of progress bar)
                // Center text into the highlighted area only
                // Point location = new Point(Convert.ToInt32((rect.Width / 2) - (len.Width / 2)), Convert.ToInt32((rect.Height / 2) - (len.Height / 2)));

                //Center text regardless of highlighted area
                Point location = new Point((Width / 2) - 10, (Height / 2) - 7);

                // Draw the custom text
                g.DrawString(text, f, Brushes.Black, location);
            }
        }
    }
}
