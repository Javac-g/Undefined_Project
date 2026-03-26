@Controller
@RequestMapping("/dashboard/domains")  
public class DomainController{

    @GetMapping("/domains")
    @ResponseBody
    public SliceResponse<DomainSummaryDTO> loadDomains( @RequestParam(defaultValue = "0") int page) {
      
          Long userId = currentUser.getUserId();
          return domainService.getSliceUserDomains(userId, page, 10);
      
        }
  
}
