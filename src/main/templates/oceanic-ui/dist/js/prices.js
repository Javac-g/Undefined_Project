$(document).ready(function () {
    $('.toggle-btn').click(function () {
        const $btn = $(this);
        const targetSelector = $btn.attr('data-target');
        const $target = $(targetSelector);

        // Check visibility immediately before toggle
        const isVisible = $target.hasClass('in') || $target.hasClass('show');

        // Toggle button text based on current state
        if (isVisible) {
            $btn.text('Show more');
        } else {
            $btn.text('Show less');
        }
    });
});