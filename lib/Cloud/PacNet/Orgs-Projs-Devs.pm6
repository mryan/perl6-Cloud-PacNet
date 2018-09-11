use Cloud::PacNet::RESTrole ;

class Cloud::PacNet::Organization does RESTrole {
    has $.id    is required ;

    method GET-projects   {  self.GET-something("/organizations/$!id/projects")              }
    method get-projects   {  self.GET-something("/organizations/$!id/projects")<projects>    }
    method POST-projects  {  self.POST-something("/organizations/$!id/projects")             }
    method create-project {  self.POST-something("/organizations/$!id/projects")             }

    method GET-devices    {  self.GET-something("/organizations/$!id/devices")               }
    method get-devices    {  self.GET-something("/organizations/$!id/devices")               }

    method GET            {  self.GET-something("/organizations/$!id")                }
    method get-details    {  self.GET-something("/organizations/$!id")                }
    method PUT(|c)        {  self.PUT-something("/organizations/$!id", |c)                   }
    method update(|c)     {  self.PUT-something("/organizations/$!id", |c)                   }
    method DELETE         {  self.DELETE-something("/organizations/$!id")             }
}


class Cloud::PacNet::Project does RESTrole {
    has $.id    is required ;

    method GET-events        {  self.GET-something("/projects/$!id/events")         }
    method get-events        {  self.GET-something("/projects/$!id/events")<events> }
    method GET-devices       {  self.GET-something("/projects/$!id/devices")        }
    method get-devices       {  self.GET-something("/projects/$!id/devices")<devices> }
    method POST-devices(|c)  {  self.POST-something("/projects/$!id/devices", |c)   }
    method create-device(|c) {  self.POST-something("/projects/$!id/devices", |c)   }
    method GET               {  self.GET-something("/projects/$!id")                }
    method get-details       {  self.GET-something("/projects/$!id")                }
    method PUT(|c)           {  self.PUT-something("/projects/$!id", |c)            }
    method update(|c)        {  self.PUT-something("/projects/$!id", |c)            }
    method DELETE            {  self.DELETE-something("/projects/$!id")             }
}

