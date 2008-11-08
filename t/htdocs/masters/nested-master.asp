<%@ MasterPage %>
<%@ Page UseMasterPage="/masters/root.asp" %>

<asp:Content id="content1" PlaceHolderID="mainholder" runat="server">
  <asp:ContentPlaceHolder id="inner_ph" runat="server">This is the default</asp:ContentPlaceHolder>
</asp:Content>

