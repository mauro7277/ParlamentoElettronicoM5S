local issues_selector = param.get("issues_selector", "table")
local member = param.get("for_member", "table") or app.session.member
local for_state = param.get("for_state")
local for_unit = param.get("for_unit", atom.boolean)

 

 
 
local event_max_id = param.get_all_cgi()["event_max_id"]
local event_selector = Event:new_selector()
  :add_order_by("event.id DESC")
  :limit(25)
  :join("issue", nil, "issue.id = event.issue_id")
  :add_field("now()::date - event.occurrence::date", "time_ago")
  
if event_max_id then
  event_selector:add_where{ "event.id < ?", event_max_id }
end
  
 
 
local last_event_id

event_selector: add_where{ "event.member_id = ?", app.session.member.id }

if for_state then

    if for_state=="open" then
        event_selector:add_where("event.state in ('admission', 'discussion', 'verification', 'voting')")
    end
    
    if for_state=="New" then
         event_selector:add_where("event.state = 'admission'")
    end
    
    if for_state=="Discussion" then
         event_selector:add_where("event.state = 'discussion'")
    end
    
    if for_state=="Frozen" then
         event_selector: add_where("event.state = 'verification'")
    end
    
    if for_state=="Voting" then
         event_selector: add_where("event.state = 'voting'")
    end
    
    if for_state=="Closed" then
         event_selector: add_where("event.state IN ('finished_with_winner', 'finished_without_winner')")
    end
    
    if for_state=="Canceled" then
         event_selector: add_where("event.state IN ('canceled_revoked_before_accepted', 'canceled_issue_not_accepted', 'canceled_after_revocation_during_discussion', 'canceled_after_revocation_during_verification')")
    
    end
    
    
end


local events = event_selector:exec()

local direct_voter

 
 ui.container{ attr = { class = "containerIssueDiv" },
     content = function()
        
--issueDIv
 ui.paginate{
    
    per_page = tonumber(param.get("per_page") or 25),
    selector = issues_selector,
    content = function()
      local highlight_string = param.get("highlight_string", "string")
      local issues = issues_selector:exec()
      issues:load_everything_for_member_id(member and member.id or nil)

--contenitore issue
      ui.container{ attr = { class = "issues" }, content = function()
        
         local _issue={}
         local _events={}
         
         trace.debug("#events(for_state="..for_state..")="..#events)
         for j,event in ipairs(events) do
                            
              if  event.member_id  ==    app.session.member.id then
                 _events[j]=event
                 trace.debug(" event.member_id == app.session.member.id :: "..event.member_id.."=="..app.session.member.id)
              end
              
         end
        
        trace.debug("#_events="..#_events)
        
        local issue_rendered=0
        for i, issue in ipairs(issues) do
--singola issue
                    if app.session.member_id then
                        direct_voter = issue.member_info.direct_voted
                    end 
                    if not direct_voter then
                    
                            if  #events>0   then
                                    
                                    for t,_e in ipairs(_events)  do
                                    
                                        if _e.issue_id==issue.id then
                                        _issue=issue
                                        end
                                    end
                                    
                                    if #_issue>0 then
                                      execute.view{ module = "issue", view = "_show_ext", params = {
                                        issue = _issue, for_listing = true, events=_events, event_id_show=i
                                      } }
                                      
                                      issue_rendered=issue_rendered+1
                                      _issue={}
                                    end
                            end  
                  end
                  
           
--spazio div         
          ui.container
          {
              attr={class="spazioIssue"},
              content=function()
          end
          }
          
        end --fine for
  
   --label "nessuna issue presente"    
          trace.debug("issue_rendered="..issue_rendered)  
          if  issue_rendered==0 then     
            ui.tag{tag="pre",
                    attr={style="font-style: italic;color:grey;margin-left:150px;"},
                    content=_"No issue suggested"
                    }
          end          
                
      end }
    end
  }
  
  end --fine containerIssue
  }
