namespace Marechal.DataverseMapping;
using Microsoft.Integration.DynamicsFieldService;
tableextension 50204 FSWorkOrderIncident extends "FS Work Order Incident"
{
    fields
    {
        // Add changes to table fields here
        field(50101; msdyn_FunctionalLocation; GUID)
        {
            ExternalName = 'msdyn_functionallocation';
            ExternalType = 'Lookup';
            Description = 'Poste technique de l’ordre de travail';
            Caption = 'Poste technique';
            TableRelation = "CDS msdyn_FunctionalLocation".msdyn_FunctionalLocationId;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

}
