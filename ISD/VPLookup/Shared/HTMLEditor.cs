using AjaxControlToolkit.HTMLEditor;
using System;
using System.Collections;
using System.Collections.ObjectModel;

/// This class is used by Add/Edit Record pages 

namespace VPLookup.UI
{

    public class HTMLEditor : Editor
    {
        AjaxControlToolkit.HTMLEditor.ToolbarButton.FontName fontName = new AjaxControlToolkit.HTMLEditor.ToolbarButton.FontName();
        AjaxControlToolkit.HTMLEditor.ToolbarButton.FontSize fontSize = new AjaxControlToolkit.HTMLEditor.ToolbarButton.FontSize();

        /// <summary>
        /// Disables the tabbing for the FontName and FontSize dropdown list
        /// When user tabs from other control to the editor, it should ignore FontName and FontSize dropdown list
        /// and takes the cursor directly inside the editor textbox 
        /// </summary>
        protected override void OnPreRender(EventArgs e)
        {            
            base.OnPreRender(e);
            fontName.IgnoreTab = true;
            fontSize.IgnoreTab = true;
        }

        /// <summary>
        /// This method is responsible for adding buttons on the TopToolbar of the editor
        /// Remove or Add the buttons provided by AjaxControlToolkit
        /// </summary>
        protected override void FillTopToolbar()
        {
            Collection<AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption> options = null;
            AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption option = default(AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption);            

            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Undo());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Redo());
            
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Bold());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Italic());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Underline());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.StrikeThrough());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.SubScript());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.SuperScript());

            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.FixedBackColor());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.BackColorSelector());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.BackColorClear());

            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.FixedForeColor());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.ForeColorSelector());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.ForeColorClear());

            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.OrderedList());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.BulletedList());
            
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Paragraph());     
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.JustifyCenter());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.JustifyFull());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.JustifyLeft());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.JustifyRight());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.RemoveAlignment());            

            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.IncreaseIndent());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.DecreaseIndent());
            
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.InsertLink());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.RemoveLink());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.InsertHR());
            
            // Uncomment this section of code to add more buttons to the editor. 
            // These buttons are commented out because of compatibility issues within the browser
            //TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());
            //TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Cut());
            //TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Copy());
            //TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Paste());
            //TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.PasteText());
            //TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.PasteWord());

            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Ltr());
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.Rtl());
            
            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());
            TopToolbar.Buttons.Add(fontName);

            options = fontName.Options;
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "arial,helvetica,sans-serif";
            option.Text = "Arial";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "courier new,courier,monospace";
            option.Text = "Courier New";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "georgia,times new roman,times,serif";
            option.Text = "Georgia";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "tahoma,arial,helvetica,sans-serif";
            option.Text = "Tahoma";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "times new roman,times,serif";
            option.Text = "Times New Roman";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "verdana,arial,helvetica,sans-serif";
            option.Text = "Verdana";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "impact";
            option.Text = "Impact";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "wingdings";
            option.Text = "WingDings";
            options.Add(option);

            TopToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HorizontalSeparator());            
            TopToolbar.Buttons.Add(fontSize);

            options = fontSize.Options;
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "8pt";
            option.Text = "1 ( 8 pt)";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "10pt";
            option.Text = "2 (10 pt)";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "12pt";
            option.Text = "3 (12 pt)";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "14pt";
            option.Text = "4 (14 pt)";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "18pt";
            option.Text = "5 (18 pt)";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "24pt";
            option.Text = "6 (24 pt)";
            options.Add(option);
            option = new AjaxControlToolkit.HTMLEditor.ToolbarButton.SelectOption();
            option.Value = "36pt";
            option.Text = "7 (36 pt)";
            options.Add(option);
        }

        /// <summary>
        /// This method is responsible for adding buttons on the BottomToolbar of the editor
        /// Remove or Add the buttons provided by AjaxControlToolkit
        /// </summary>
        protected override void FillBottomToolbar()
        {
            BottomToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.DesignMode());
            BottomToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.PreviewMode());
            BottomToolbar.Buttons.Add(new AjaxControlToolkit.HTMLEditor.ToolbarButton.HtmlMode());
        }
    }

}
