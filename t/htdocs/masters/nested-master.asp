<%@ MasterPage %>
<%@ Page UseMasterPage="/masters/root.asp" %>

<asp:PlaceHolderContent id="content1" PlaceHolderID="mainholder" runat="server">
  <asp:PlaceHolder id="inner_ph" runat="server">This is the default</asp:PlaceHolder>
</asp:PlaceHolderContent>

