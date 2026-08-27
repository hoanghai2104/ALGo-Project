namespace Marechal.DataverseMapping.CRM;
using Microsoft.Integration.D365Sales;

tableextension 50129 CRMProductExt extends "CRM Product"
{
    fields
    {
        field(50100; phma_BCCategorieTexte; Text[100])
        {
            ExternalName = 'phma_bccategorietexte';
            ExternalType = 'String';
            Description = '';
            Caption = 'BC Categorie Texte';
        }
    }


}
