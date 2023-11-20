
/* CONS EXEC  */                                                                  
                                                                                
parse arg option fname ftype                                                    
upper option                                                                    
if option = '' then  SAY 'Syntax:  CONS ON   | OFF'         
if option = 'ON' then do                                                        
   if fname = '' then do                                                        
      say 'Invalid Syntax - Filename needed.';                                  
      return  ;                                                                 
   end ;                                                                        
   if ftype = '' then do                                                        
      say 'Invalid Syntax - Filetype needed.';                                  
      return  ;                                                                 
   end ;                                                                        
   'CP SPOOL CONS * RDR START NAME ' fname ' ' ftype                            
   say 'Console log started.'                                                   
end ;                                                                           
if option = 'OFF' then do                                                       
   'CP SPOOL CONS STOP CLOSE'                                                   
   say 'Console log closed and sent to your RDR.'                               
end ;
