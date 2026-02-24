package com.pinesdigital;

@Controller
public class AuthController {

    private final RegistrationService registrationService;
    private final MembershipService membershipService;
    private final SubscriptionRepository subscriptionRepository;

    public AuthController(RegistrationService registrationService,
                          MembershipService membershipService,
                          SubscriptionRepository subscriptionRepository) {

        this.membershipService = membershipService;
        this.registrationService = registrationService;
        this.subscriptionRepository = subscriptionRepository;
    }

    @GetMapping("/login")
    public String loginPage() {
        return "login";
    }
    @GetMapping("/main")
    public String mainPage() {
        return "main";
    }


    @GetMapping("/registration")
    public String registerPage( Model model) {
        model.addAttribute("plans", membershipService.getAll());
        return "registration";
    }

    @PostMapping("/registration")
    public String register(
            @RequestParam String username,
            @RequestParam String email,
            @RequestParam String password,
            @RequestParam String firstName,
            @RequestParam String lastName,
            @RequestParam Long planId,
            Model model
    ) {

        try {
           User user = registrationService.register(username,
                    email,
                    password,
                    firstName + " " + lastName);
            MembershipPlan plan = membershipService.getPlanById(planId);

            Subscription sub = new Subscription();
            sub.setUser(user);
            sub.setPlan(plan);
            Instant start = Instant.now();
            sub.setStartAt(start);
            sub.setEndAt(start.plus(plan.getDurationDays(), ChronoUnit.DAYS));
            sub.setStatus(SubscriptionStatus.ACTIVE);

            subscriptionRepository.save(sub);
            return "redirect:/login?registered";
        } catch (Exception ex) {
            model.addAttribute("error", ex.getMessage());
            return "registration";
        }
    }
}
