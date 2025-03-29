#!/bin/bash
set -e

echo "Starting WordPress development data population..."

# Check if WordPress is installed
if ! wp core is-installed --path=/var/www/html; then
    echo "WordPress is not installed. Please run setup.sh first."
    exit 1
fi

# Check if BuddyPress is active
if ! wp plugin is-active buddypress --path=/var/www/html; then
    echo "BuddyPress is not active. Please run setup.sh first."
    exit 1
fi

# Make sure components are all initialized
echo "Checking BuddyPress components..."
wp bp component list --path=/var/www/html || true

echo "Creating example users with Latin names..."
# Array of Roman first names
first_names=(
    "Marcus" "Julius" "Gaius" "Titus" "Lucius" "Publius" "Quintus" "Aulus" "Decimus" "Servius"
    "Livia" "Julia" "Claudia" "Octavia" "Antonia" "Valeria" "Cornelia" "Aurelia" "Flavia" "Domitia"
)

# Array of Roman family names
last_names=(
    "Aurelius" "Caesar" "Cicero" "Seneca" "Varro" "Cato" "Tullius" "Tacitus" "Augustus" "Antonius"
    "Brutus" "Cassius" "Scipio" "Gracchus" "Sulla" "Marius" "Crassus" "Agrippa" "Tiberius" "Claudius"
)

# Create 20 example users with Latin names
for i in {1..20}; do
    # Select random first and last name
    rand_first=$((RANDOM % ${#first_names[@]}))
    rand_last=$((RANDOM % ${#last_names[@]}))
    
    first_name="${first_names[$rand_first]}"
    last_name="${last_names[$rand_last]}"
    username=$(echo "${first_name}${last_name}" | tr '[:upper:]' '[:lower:]')
    email="$username@example.com"
    password="password"
    
    if ! wp user get "$username" --path=/var/www/html --field=user_login &>/dev/null; then
        wp user create "$username" "$email" --user_pass="$password" --first_name="$first_name" --last_name="$last_name" --role=subscriber --path=/var/www/html
    else
        echo "User $username already exists. Skipping."
    fi
done

echo "Creating example posts..."
# Create 20 example posts randomly assigned to different users
for i in {1..20}; do
    # Get random user ID between 2-11 (skipping admin which is usually ID 1)
    user_id=$((RANDOM % 10 + 2))
    
    # Check if user exists
    if ! wp user get $user_id --path=/var/www/html &>/dev/null; then
        echo "User with ID $user_id doesn't exist. Using admin instead."
        user_id=1
    fi
    
    # Array of interesting post titles
    post_titles=(
        "De Finibus Bonorum et Malorum" 
        "Ars Poetica" 
        "Commentarii de Bello Gallico" 
        "Metamorphoses" 
        "Aeneid Book VI" 
        "De Rerum Natura" 
        "Meditations on the First Philosophy" 
        "Epistulae Morales ad Lucilium" 
        "The Republic of Plato" 
        "Historia Naturalis"
        "De Architectura" 
        "Institutio Oratoria" 
        "Annals of Imperial Rome" 
        "Confessions of Augustine" 
        "Ara Pacis Augustae" 
        "Satyricon" 
        "On the Nature of Things" 
        "Carmina Burana" 
        "The City of God" 
        "Phaedrus"
    )
    
    title="${post_titles[i-1]}"
    
    # Lorem Ipsum paragraphs for content
    lorem_paragraphs=(
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam dapibus efficitur libero, in gravida nibh mattis non. Suspendisse quis hendrerit quam. Donec ut elementum erat, sit amet vulputate nisi. Fusce rutrum tellus et purus semper, a cursus magna vestibulum. Proin eget ligula nec ligula volutpat tincidunt. Cras vel commodo dolor, sed porta tellus. Fusce condimentum neque in risus maximus, id scelerisque nulla finibus."
        
        "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt."
        
        "At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio."
        
        "Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus."
        
        "Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem."
    )
    
    # Combine 2-3 random paragraphs for content
    num_paragraphs=$((RANDOM % 2 + 2))
    content=""
    
    for p in $(seq 1 $num_paragraphs); do
        para_index=$((RANDOM % ${#lorem_paragraphs[@]}))
        content+="${lorem_paragraphs[$para_index]}\n\n"
    done
    
    post_id=$(wp post create --post_title="$title" --post_content="$content" --post_status="publish" --post_author="$user_id" --porcelain --path=/var/www/html)
    echo "Created post ID: $post_id by user ID: $user_id"
    
    # Add between 1-5 comments to each post
    comment_count=$((RANDOM % 5 + 1))
    for j in {1..5}; do
        if [ $j -le $comment_count ]; then
            # Get random user ID for comment
            commenter_id=$((RANDOM % 10 + 2))
            if ! wp user get $commenter_id --path=/var/www/html &>/dev/null; then
                commenter_id=1
            fi
            
            # Array of philosophical comments
            comments=(
                "I must disagree with the author's premise. The text clearly indicates a stoic influence rather than an epicurean one."
                "The eloquence of this passage reminds me of Cicero's earlier works. Sublime in its simplicity."
                "What a magnificent exploration of virtue and wisdom! The author channels the spirit of Marcus Aurelius."
                "This argument fails to consider the Aristotelian perspective, which would add valuable context."
                "Indeed, this recalls the central thesis of Seneca's letters on ethics. Well articulated."
                "The paradox presented here is reminiscent of Zeno's finest dialectics. A challenging read!"
                "One cannot help but think of Plato's allegory when reading this masterful prose."
                "While beautifully written, I find the logic somewhat circular. Socrates would have questioned this approach."
                "The rhetorical strategy employed here would make Quintilian proud. A masterclass in persuasion."
                "Such profound insights! This clearly builds upon earlier philosophical traditions while adding novel perspectives."
                "I'm struck by the parallels to ancient Pythagorean thought. Was this influence intentional?"
                "The moral implications of this text deserve deeper consideration. What would Cato say?"
                "A compelling case, though I wonder how it aligns with the teachings of Epictetus."
                "The author's treatment of truth and perception echoes the skepticism of Pyrrho."
                "This beautiful prose masks some troubling contradictions in the underlying argument."
            )
            
            comment_index=$((RANDOM % ${#comments[@]}))
            
            wp comment create --comment_post_ID="$post_id" --comment_content="${comments[$comment_index]}" --comment_author="$(wp user get $commenter_id --field=display_name --path=/var/www/html)" --comment_author_email="$(wp user get $commenter_id --field=user_email --path=/var/www/html)" --path=/var/www/html
            
            # 50% chance to add a reply to this comment
            if [ $((RANDOM % 2)) -eq 0 ]; then
                parent_comment_id=$(wp comment list --post_id="$post_id" --format=ids --number=1 --path=/var/www/html)
                if [ -n "$parent_comment_id" ]; then
                    replier_id=$((RANDOM % 10 + 2))
                    if ! wp user get $replier_id --path=/var/www/html &>/dev/null; then
                        replier_id=1
                    fi
                    
                    # Array of philosophical replies
                    replies=(
                        "I appreciate your perspective, though I believe you've misinterpreted the Platonic influence in this passage."
                        "Your analysis shows considerable insight. Have you considered how this relates to the Pythagorean school?"
                        "While I agree with your assessment, I think you overlook the crucial Aristotelian elements present throughout."
                        "A thoughtful commentary, indeed. However, the Stoic undertones seem more prominent than you suggest."
                        "Your point about the rhetorical structure is well-taken, though I find the logical framework more Aristotelian than Ciceronian."
                        "I must respectfully disagree. The author's position seems more aligned with Epicurean thought than Stoicism."
                        "An erudite observation! The dialectical method employed here does indeed echo classical influences."
                        "Your comparison to Seneca is apt, though I detect more of Epictetus in the moral reasoning presented."
                        "A brilliant analysis. I would add that the epistemological framework owes much to the Academic Skeptics."
                        "I find your interpretation intriguing but would suggest the influence is more Neoplatonic than purely Platonic."
                    )
                    
                    reply_index=$((RANDOM % ${#replies[@]}))
                    
                    wp comment create --comment_post_ID="$post_id" --comment_parent="$parent_comment_id" --comment_content="${replies[$reply_index]}" --comment_author="$(wp user get $replier_id --field=display_name --path=/var/www/html)" --comment_author_email="$(wp user get $replier_id --field=user_email --path=/var/www/html)" --path=/var/www/html
                fi
            fi
        fi
    done
done

# If BuddyPress is active, create some BuddyPress content
if wp plugin is-active buddypress --path=/var/www/html && wp bp component list --path=/var/www/html | grep -q 'groups.*true'; then
    echo "Creating BuddyPress groups and activities..."
    
    # Create 5 BuddyPress groups
    for i in {1..5}; do
        creator_id=$((RANDOM % 10 + 2))
        if ! wp user get $creator_id --path=/var/www/html &>/dev/null; then
            creator_id=1
        fi
        
        # Array of philosophical group names and descriptions
        group_names=(
            "The Stoic Circle" 
            "Peripatetic Society" 
            "Epicurean Garden" 
            "Platonic Academy" 
            "Cynics Anonymous"
        )
        
        group_descriptions=(
            "A gathering place for those who follow the Stoic philosophy of Zeno, Seneca, and Marcus Aurelius. Here we discuss virtue, rationality, and living in accordance with nature."
            "Named after Aristotle's habit of walking while teaching, our society explores metaphysics, ethics, politics, and the golden mean. All those seeking knowledge are welcome."
            "Following Epicurus, we believe in the pursuit of modest pleasures and the absence of pain and fear. Join us to explore tranquility and the simple joys of life."
            "Dedicated to the dialogues and teachings of Plato, exploring forms, ideas, and the pursuit of wisdom. Socratic discussions every Thursday."
            "Rejecting social conventions and embracing a simple life in accordance with nature. All materialists will be mercilessly mocked."
        )
        
        group_name="${group_names[$i-1]}"
        group_desc="${group_descriptions[$i-1]}"
        
        # Create group
        group_id=$(wp bp group create --name="$group_name" --description="$group_desc" --creator-id="$creator_id" --path=/var/www/html --porcelain)
        
        # Add random members to group
        for j in {1..8}; do
            member_id=$((RANDOM % 10 + 2))
            if wp user get $member_id --path=/var/www/html &>/dev/null; then
                wp bp group member add --group-id="$group_id" --user-id="$member_id" --path=/var/www/html || true
            fi
        done
        
        # Create some activity updates
        for k in {1..3}; do
            activity_author=$((RANDOM % 10 + 2))
            if ! wp user get $activity_author --path=/var/www/html &>/dev/null; then
                activity_author=1
            fi
            
            # Array of philosophical activity updates for each group type
            stoic_activities=(
                "Just finished reading Seneca's 'Letters from a Stoic'. Who else has insights to share on his views of friendship?"
                "Practicing negative visualization today. Imagining the loss of what I value to appreciate it more fully."
                "Marcus Aurelius reminds us: 'You have power over your mind - not outside events. Realize this, and you will find strength.'"
                "Question for the group: How do you practice Stoic mindfulness in your daily life?"
                "Remember that we cannot control external events, only our responses to them. How is everyone applying this today?"
            )
            
            peripatetic_activities=(
                "Contemplating Aristotle's concept of eudaimonia today. Is happiness truly activity of the soul in accordance with virtue?"
                "Walking discussions - literally peripatetic! Anyone want to join this Saturday for philosophy in motion?"
                "Reading Aristotle's 'Nicomachean Ethics'. His concept of the golden mean seems particularly relevant in today's polarized world."
                "Virtue as a mean between extremes - how does this apply to courage in modern life? Thoughts?"
                "Exploring the categorical syllogism as a method of deductive reasoning. Examples welcome!"
            )
            
            epicurean_activities=(
                "Simple dinner gathering this Friday - good food, good conversation, good friends. The essence of Epicurean living."
                "Reminder: true pleasure isn't excessive indulgence, but freedom from pain and mental disturbance."
                "Finding ataraxia (tranquility) through simplifying life choices. What have you eliminated that brought peace?"
                "Natural and necessary desires vs vain desires - how do you distinguish between them in your life?"
                "Reading group for Lucretius' 'On the Nature of Things' starts next week. Sign up now!"
            )
            
            platonic_activities=(
                "Debating the allegory of the cave - how do we recognize the shadows on our own walls?"
                "Reading group forming for Plato's Republic, Books VI-VII. Focus on the theory of Forms."
                "Theory of recollection: Do we really know nothing, or simply forget what our souls once knew?"
                "Wisdom, courage, moderation, justice - the four cardinal virtues. Which do you find most challenging to embody?"
                "Dialectic practice session this Thursday. Bring your strongest arguments to be systematically examined!"
            )
            
            cynic_activities=(
                "Diogenes lived in a barrel to demonstrate self-sufficiency. What's your modern equivalent of barrel-living?"
                "Conventional wisdom challenged: Why do we work so hard for things we don't need to impress people we don't like?"
                "Walking barefoot meditation tomorrow at dawn. Clothing optional, shamelessness mandatory."
                "Remember: A dog has no use for fancy furnishings or social status. Be more dog-like!"
                "Challenge of the week: Identify one social convention you follow without question, then deliberately break it."
            )
            
            # Select appropriate activity based on group type
            case $i in
                1) activities=("${stoic_activities[@]}") ;;
                2) activities=("${peripatetic_activities[@]}") ;;
                3) activities=("${epicurean_activities[@]}") ;;
                4) activities=("${platonic_activities[@]}") ;;
                5) activities=("${cynic_activities[@]}") ;;
                *) activities=("${stoic_activities[@]}") ;;
            esac
            
            activity_index=$((RANDOM % ${#activities[@]}))
            activity_content="${activities[$activity_index]}"
            
            wp bp activity create --component=groups --type=activity_update --user-id="$activity_author" --content="$activity_content" --item-id="$group_id" --path=/var/www/html
        done
    done
fi

echo "Creating sample pages..."
# Create philosophical pages
page_titles=(
    "Philosophical Categories" 
    "Historical Timeline" 
    "Major Works" 
    "Ethical Systems" 
    "Symposium Registration"
)

page_contents=(
    "<h2>Major Philosophical Categories</h2>

<h3>Metaphysics</h3>
Study of the nature of reality, including the relationship between mind and matter, substance and attribute, potentiality and actuality.

<h3>Epistemology</h3>
Study of the nature and grounds of knowledge especially with reference to its limits and validity.

<h3>Ethics</h3>
Study of moral principles that govern a person's behavior or the conducting of an activity.

<h3>Logic</h3>
Study of valid reasoning and the principles that distinguish good (correct) reasoning from bad (incorrect) reasoning.

<h3>Aesthetics</h3>
Study of the nature of beauty, art, taste, and the creation and appreciation of beauty."

    "<h2>Historical Timeline of Western Philosophy</h2>

<h3>Ancient Period (600 BCE-500 CE)</h3>
<ul>
<li>Pre-Socratics (Thales, Heraclitus, Parmenides)</li>
<li>Classical Greek (Socrates, Plato, Aristotle)</li>
<li>Hellenistic and Roman (Epicureans, Stoics, Skeptics)</li>
<li>Neoplatonism (Plotinus)</li>
</ul>

<h3>Medieval Period (500-1500)</h3>
<ul>
<li>Early Christian thought (Augustine)</li>
<li>Islamic philosophy (Avicenna, Averroes)</li>
<li>Scholasticism (Anselm, Aquinas, Ockham)</li>
</ul>

<h3>Renaissance and Early Modern (1500-1800)</h3>
<ul>
<li>Rationalism (Descartes, Spinoza, Leibniz)</li>
<li>Empiricism (Locke, Berkeley, Hume)</li>
<li>Enlightenment (Kant, Rousseau)</li>
</ul>

<h3>19th Century</h3>
<ul>
<li>German Idealism (Fichte, Schelling, Hegel)</li>
<li>Utilitarianism (Bentham, Mill)</li>
<li>Marxism (Marx, Engels)</li>
<li>Existentialism (Kierkegaard, Nietzsche)</li>
</ul>

<h3>20th Century</h3>
<ul>
<li>Analytic Philosophy (Russell, Wittgenstein, Quine)</li>
<li>Phenomenology (Husserl, Heidegger, Sartre)</li>
<li>Pragmatism (Peirce, James, Dewey)</li>
<li>Post-structuralism (Foucault, Derrida)</li>
</ul>"

    "<h2>Major Philosophical Works</h2>

<ol>
<li><strong>Republic</strong> - Plato</li>
<li><strong>Nicomachean Ethics</strong> - Aristotle</li>
<li><strong>Meditations</strong> - Marcus Aurelius</li>
<li><strong>Summa Theologica</strong> - Thomas Aquinas</li>
<li><strong>Discourse on Method</strong> - René Descartes</li>
<li><strong>Ethics</strong> - Baruch Spinoza</li>
<li><strong>An Essay Concerning Human Understanding</strong> - John Locke</li>
<li><strong>Critique of Pure Reason</strong> - Immanuel Kant</li>
<li><strong>Phenomenology of Spirit</strong> - G.W.F. Hegel</li>
<li><strong>On Liberty</strong> - John Stuart Mill</li>
<li><strong>Thus Spoke Zarathustra</strong> - Friedrich Nietzsche</li>
<li><strong>Being and Time</strong> - Martin Heidegger</li>
<li><strong>A Theory of Justice</strong> - John Rawls</li>
</ol>"

    "<h2>Major Ethical Systems</h2>

<h3>Virtue Ethics</h3>
Emphasizes the character of the person performing actions. Originated with Aristotle's concept of eudaimonia or human flourishing. Virtues like courage, honesty, and justice are developed through practice.

<h3>Deontological Ethics</h3>
Focuses on the rightness or wrongness of actions themselves, rather than consequences. Kant's categorical imperative is a prime example, suggesting one should act only according to that maxim by which you can at the same time will that it should become a universal law.

<h3>Consequentialism</h3>
Judges the rightness of an action based on its consequences. Utilitarianism is the most common form, proposing that the most ethical choice is the one that produces the greatest good for the greatest number.

<h3>Care Ethics</h3>
Emphasizes the importance of response to the needs of others, particularly relationships of care. It values empathy and interpersonal relationships.

<h3>Natural Law Ethics</h3>
Posits that ethical rules are inherent in nature and can be discovered through reason. Humans have inherent purposes which help us understand moral behavior."

    "<h2>Annual Philosophy Symposium Registration</h2>

<p>Join us for this year's symposium on 'Classical Wisdom in the Modern World'</p>

<h3>Event Details</h3>
<ul>
<li><strong>Date:</strong> October 15-17, 2023</li>
<li><strong>Location:</strong> Athens Conference Center</li>
<li><strong>Registration Fee:</strong> $250 (early bird), $350 (regular)</li>
</ul>

<h3>Keynote Speakers</h3>
<ul>
<li>Professor Martha Nussbaum - 'Stoicism and Emotional Resilience'</li>
<li>Dr. Michael Sandel - 'Aristotle on Justice and Virtue'</li>
<li>Professor Peter Singer - 'Effective Altruism: Epicurean and Utilitarian Approaches'</li>
</ul>

<h3>Breakout Sessions</h3>
<ul>
<li>Plato's Cave in the Digital Age</li>
<li>Aristotelian Ethics in Business Leadership</li>
<li>Stoic Mindfulness Practices</li>
<li>Cynicism as Social Critique</li>
<li>Epicurean Approaches to Happiness</li>
</ul>

<p>Register by August 1st for early bird pricing. All participants will receive a collection of selected readings and access to recorded sessions.</p>"
)

for i in {1..5}; do
    page_title="${page_titles[$i-1]}"
    page_content="${page_contents[$i-1]}"
    
    wp post create --post_type=page --post_title="$page_title" --post_content="$page_content" --post_status="publish" --path=/var/www/html
done

echo "Creating messages to admin..."
# Get admin user ID (usually 1)
admin_id=1

# Verify the admin user exists
if ! wp user get $admin_id --path=/var/www/html &>/dev/null; then
    echo "Admin user not found. Skipping messages to admin."
else
    # First check if BuddyPress Messages component is active
    if wp bp component list --format=json --path=/var/www/html | grep -q '"component_id":"messages".*"is_active":true'; then
        echo "Sending private messages to admin..."
        
        # Get all users except admin
        user_ids=$(wp user list --field=ID --exclude=$admin_id --path=/var/www/html)
        
        # Array of message subjects and contents
        message_subjects=(
            "Greetings from a new member" 
            "Question about group policies"
            "Technical issue with the site"
            "Suggestion for future discussions"
            "Thank you for maintaining this community"
            "Request for philosophical guidance"
            "Collaboration proposal"
            "Requesting reading recommendations"
            "Problems accessing resources"
            "Introducing myself"
        )
        
        message_contents=(
            "Salve! I am new to the forums and wanted to introduce myself. I've been studying Stoicism for several years and look forward to meaningful discussions here."
            
            "I noticed that our group has no clear policy on off-topic discussions. Could we establish some guidelines to keep conversations focused on philosophical themes?"
            
            "When I try to upload my avatar, I receive an error message. Could you help me resolve this technical issue?"
            
            "Have you considered creating a monthly book club? I believe it would enhance our community's engagement with primary texts."
            
            "I wanted to express my gratitude for maintaining this philosophical haven. The quality of discussion here far exceeds other online forums."
            
            "I've been struggling with applying philosophical principles to a personal dilemma. Would you be willing to offer some Stoic perspective on my situation?"
            
            "I'm organizing a symposium on virtue ethics next month and would be honored if you would consider participating as a speaker."
            
            "Could you recommend some introductory texts on Epicureanism? I'm particularly interested in how it compares to modern hedonism."
            
            "I cannot access the archived discussions from last year's symposium. Are these resources still available somewhere?"
            
            "As a new member, I thought I should introduce myself. I have a background in classical studies and am particularly interested in pre-Socratic thought."
        )
        
        # For each user, send a message to admin
        for user_id in $user_ids; do
            # Get random subject and content
            subject_index=$((RANDOM % ${#message_subjects[@]}))
            content_index=$((RANDOM % ${#message_contents[@]}))
            
            wp bp message send --from=$user_id --to=$admin_id --subject="${message_subjects[$subject_index]}" --content="${message_contents[$content_index]}" --path=/var/www/html || true
        done
    else
        echo "BuddyPress Messages component not active. Skipping messages to admin."
    fi
fi

# region: TUTORIAL CONTENT
echo "Creating BuddyPress & BuddyX tutorial curriculum..."

# Check if BuddyPress is active and installed
if ! wp plugin is-active buddypress --path=/var/www/html; then
    echo "BuddyPress is not active. Attempting to activate..."
    if wp plugin activate buddypress --path=/var/www/html; then
        echo "BuddyPress activated successfully."
    else
        echo "BuddyPress activation failed. Skipping tutorial content creation."
        return 1
    fi
fi

# Proceed with creating tutorial content
    # Create main tutorial category
    tutorial_cat_id=$(wp term create category "BuddyPress Tutorials" --porcelain --path=/var/www/html)
    
    # Create subcategories for different tutorial types
    basics_cat_id=$(wp term create category "Getting Started" --parent=$tutorial_cat_id --porcelain --path=/var/www/html)
    groups_cat_id=$(wp term create category "Managing Groups" --parent=$tutorial_cat_id --porcelain --path=/var/www/html)
    members_cat_id=$(wp term create category "Member Management" --parent=$tutorial_cat_id --porcelain --path=/var/www/html)
    activity_cat_id=$(wp term create category "Activity Streams" --parent=$tutorial_cat_id --porcelain --path=/var/www/html)
    buddyx_cat_id=$(wp term create category "BuddyX Theme" --parent=$tutorial_cat_id --porcelain --path=/var/www/html)
    
    # Array of tutorial posts organized by category
    # Format: "Title|Content|Category ID|Order Number"
    
    # Getting Started Tutorials
    basics_tutorials=(
        "Introduction to BuddyPress|<h2>Welcome to BuddyPress!</h2>
<p>BuddyPress transforms your WordPress site into a vibrant social network. This tutorial series will help you understand how to use BuddyPress to build a thriving online community.</p>

<h3>What is BuddyPress?</h3>
<p>BuddyPress is a powerful plugin that adds social networking features to your WordPress site, including:</p>
<ul>
<li>User profiles and extended profile fields</li>
<li>Member connections (friendships)</li>
<li>Private messaging</li>
<li>Activity streams</li>
<li>User groups</li>
<li>Discussion forums (with bbPress integration)</li>
</ul>

<h3>Key Components</h3>
<p>The essential components of BuddyPress include:</p>
<ol>
<li><strong>Extended Profiles</strong>: Allow members to share information about themselves</li>
<li><strong>Activity Streams</strong>: Display user activity across the site</li>
<li><strong>Notifications</strong>: Alert users to relevant activity</li>
<li><strong>Connections</strong>: Let users establish relationships</li>
<li><strong>Groups</strong>: Enable users to form communities around shared interests</li>
<li><strong>Private Messaging</strong>: Facilitate direct communication between members</li>
</ol>

<p>In this tutorial series, we'll explore each of these components in detail and show you how to configure them for your community.</p>|$basics_cat_id|1"
        
        "Installing and Configuring BuddyPress|<h2>Setting Up BuddyPress</h2>
<p>This tutorial guides you through the installation and initial configuration of BuddyPress on your WordPress site.</p>

<h3>Installation</h3>
<ol>
<li>Log in to your WordPress admin dashboard</li>
<li>Go to Plugins > Add New</li>
<li>Search for \"BuddyPress\"</li>
<li>Click \"Install Now\"</li>
<li>Click \"Activate\" after installation completes</li>
</ol>

<h3>Initial Configuration</h3>
<p>After activation, you'll see a new \"BuddyPress\" menu in your WordPress admin. Complete these initial setup steps:</p>

<ol>
<li>Go to BuddyPress > Components to enable the features you want</li>
<li>Go to BuddyPress > Settings to configure general behavior</li>
<li>Go to BuddyPress > Pages to see which pages were created</li>
</ol>

<h3>Component Selection</h3>
<p>The core components include:</p>
<ul>
<li><strong>Extended Profiles</strong>: RECOMMENDED - Allows users to customize their profiles</li>
<li><strong>Account Settings</strong>: RECOMMENDED - Gives users control over account preferences</li>
<li><strong>Activity Streams</strong>: RECOMMENDED - Shows recent activity across your site</li>
<li><strong>Notifications</strong>: RECOMMENDED - Alerts members about relevant activity</li>
<li><strong>Member Connections</strong>: Allows members to connect as friends</li>
<li><strong>Private Messaging</strong>: Enables direct communication between members</li>
<li><strong>User Groups</strong>: Lets members create and join groups</li>
<li><strong>Site Tracking</strong>: Logs member activity across your WordPress site</li>
</ul>

<p>Enable the components that best suit your community's needs.</p>

<h3>Testing Your Setup</h3>
<p>After configuration, test the following:</p>
<ol>
<li>Visit your site's front-end to verify BuddyPress pages are accessible</li>
<li>Register a test user account</li>
<li>Complete your profile</li>
<li>Post an update to the activity stream</li>
</ol>

<p>In the next tutorial, we'll explore how to customize member profiles.</p>|$basics_cat_id|2"
        
        "Customizing Member Profiles|<h2>Enhancing User Profiles</h2>
<p>One of BuddyPress's most powerful features is its extended profile fields. This tutorial shows you how to create a rich profile experience for your community members.</p>

<h3>Understanding Profile Fields</h3>
<p>BuddyPress organizes profile information into field groups, which contain individual fields. This hierarchical structure helps organize information logically.</p>

<h3>Creating Profile Field Groups</h3>
<ol>
<li>Go to Users > Profile Fields in your WordPress admin</li>
<li>Click \"Add New Field Group\"</li>
<li>Enter a name (e.g., \"Personal Information\" or \"Professional Background\")</li>
<li>Set the description and visibility options</li>
<li>Click \"Save\"</li>
</ol>

<h3>Adding Profile Fields</h3>
<p>For each field group, you can add various field types:</p>
<ol>
<li>Text Box: For short text responses</li>
<li>Text Area: For longer text entries</li>
<li>Radio Buttons: For selecting one option from several</li>
<li>Checkboxes: For selecting multiple options</li>
<li>Dropdown: For selecting one option from a list</li>
<li>Multi-select: For selecting multiple options from a list</li>
<li>Date Selector: For selecting dates</li>
<li>URL: For website links</li>
</ol>

<h3>Field Configuration Options</h3>
<p>When creating a field, you can configure:</p>
<ul>
<li><strong>Required</strong>: Whether users must complete this field</li>
<li><strong>Visibility</strong>: Who can see this field (public, members, friends, private)</li>
<li><strong>Default Visibility</strong>: Initial visibility setting</li>
<li><strong>Allow Custom Visibility</strong>: Let users change visibility per field</li>
</ul>

<h3>Example: Professional Profile</h3>
<p>Here's a practical example for a professional network:</p>

<p><strong>Field Group</strong>: Professional Background</p>
<ol>
<li>Text Box: Current Position</li>
<li>Text Box: Company/Organization</li>
<li>Text Area: Professional Bio</li>
<li>Dropdown: Industry (with predefined options)</li>
<li>Text Box: Years of Experience</li>
<li>URL: LinkedIn Profile</li>
</ol>

<p>In the next tutorial, we'll explore the activity stream and how members can interact with each other.</p>|$basics_cat_id|3"
        
        "Navigating the BuddyPress Interface|<h2>Getting Around in BuddyPress</h2>
<p>This tutorial helps new users understand the BuddyPress interface and navigate its various sections.</p>

<h3>Main Navigation Areas</h3>
<p>After installing BuddyPress, your site will include these key navigation elements:</p>

<ol>
<li><strong>Members Directory</strong>: Lists all members of your community</li>
<li><strong>Groups Directory</strong>: Shows all available groups (if Groups component is active)</li>
<li><strong>Activity Stream</strong>: Displays recent activity across the site</li>
<li><strong>Personal Menu</strong>: Gives access to the logged-in user's profile, messages, and settings</li>
</ol>

<h3>Understanding the Activity Stream</h3>
<p>The activity stream is the central hub of your community, showing:</p>
<ul>
<li>Status updates from members</li>
<li>New friendships formed</li>
<li>Group creation and membership events</li>
<li>New forum topics and replies</li>
<li>Blog post publications (if enabled)</li>
</ul>

<p>Members can interact with activity items by:</p>
<ul>
<li>Liking/favoriting updates</li>
<li>Commenting on updates</li>
<li>Sharing updates (if enabled)</li>
</ul>

<h3>Your Profile Area</h3>
<p>Each member has a profile area with these sections:</p>
<ul>
<li><strong>Profile</strong>: View and edit personal information</li>
<li><strong>Activity</strong>: Personal activity stream</li>
<li><strong>Friends</strong>: Manage connections (if enabled)</li>
<li><strong>Groups</strong>: View group memberships (if enabled)</li>
<li><strong>Messages</strong>: Access private conversations (if enabled)</li>
<li><strong>Settings</strong>: Modify account preferences</li>
</ul>

<h3>Notification System</h3>
<p>BuddyPress notifies you about relevant activity:</p>
<ul>
<li>Friend requests</li>
<li>Messages received</li>
<li>Mentions in updates</li>
<li>Group invitations</li>
<li>Replies to your content</li>
</ul>
<p>Check your notifications through the bell icon in the navigation bar.</p>

<p>In the next tutorial, we'll discuss how to interact effectively in the community.</p>|$basics_cat_id|4"
    )
    
    # Group Management Tutorials
    groups_tutorials=(
        "Creating and Managing Groups|<h2>Building Communities with BuddyPress Groups</h2>
<p>Groups are a powerful way to organize your community around shared interests or goals. This tutorial explains how to create and manage BuddyPress groups.</p>

<h3>Understanding Group Types</h3>
<p>BuddyPress supports three types of groups:</p>
<ul>
<li><strong>Public</strong>: Visible to everyone, anyone can join</li>
<li><strong>Private</strong>: Visible in directories, but joining requires approval</li>
<li><strong>Hidden</strong>: Not listed in directories, members must be invited</li>
</ul>

<h3>Creating a New Group</h3>
<ol>
<li>Navigate to Groups > Create a Group</li>
<li>Enter the group name, description, and choose privacy settings</li>
<li>Upload a group avatar and cover image (optional)</li>
<li>Configure group settings</li>
<li>Invite initial members (optional)</li>
<li>Complete creation</li>
</ol>

<h3>Group Administration</h3>
<p>As a group admin, you can:</p>
<ul>
<li>Modify group details and settings</li>
<li>Manage membership (approve/deny requests, remove members)</li>
<li>Assign roles (admin, moderator, member)</li>
<li>Enable/disable group features</li>
<li>Delete the group if necessary</li>
</ul>

<h3>Group Roles Explained</h3>
<ul>
<li><strong>Admin</strong>: Full control over group settings and membership</li>
<li><strong>Moderator</strong>: Can approve members and moderate content</li>
<li><strong>Member</strong>: Can participate in group activities</li>
</ul>

<h3>Activating Group Features</h3>
<p>Groups can include various features:</p>
<ul>
<li>Forum discussions (requires bbPress)</li>
<li>Photo albums</li>
<li>Documents sharing</li>
<li>Group-specific activity feed</li>
</ul>
<p>Enable these in the group settings area.</p>

<h3>Best Practices for Group Management</h3>
<ol>
<li>Create clear group guidelines</li>
<li>Appoint multiple admins/moderators for active groups</li>
<li>Regularly engage with group content</li>
<li>Archive inactive groups rather than deleting them</li>
</ol>

<p>In the next tutorial, we'll explore strategies for fostering active group participation.</p>|$groups_cat_id|1"
        
        "Setting Up Group Discussions|<h2>Facilitating Conversations in BuddyPress Groups</h2>
<p>Group discussions are the heart of community engagement. This tutorial covers how to set up and manage effective discussions in your BuddyPress groups.</p>

<h3>Enabling Group Forums</h3>
<p>To enable discussions in your groups:</p>
<ol>
<li>Ensure bbPress is installed and activated</li>
<li>Go to BuddyPress > Settings > Group Settings</li>
<li>Enable the \"Group Forums\" option</li>
<li>In each group's admin panel, enable the Forums feature</li>
</ol>

<h3>Creating Discussion Categories</h3>
<p>Organize conversations by creating forum categories:</p>
<ol>
<li>Navigate to the group's Forum tab</li>
<li>As an admin, select \"Add New Topic Category\"</li>
<li>Name the category (e.g., \"General Discussion\" or \"Resources\")</li>
<li>Add a description to clarify its purpose</li>
<li>Set any category-specific rules or guidelines</li>
</ol>

<h3>Starting New Topics</h3>
<p>To initiate a discussion:</p>
<ol>
<li>Go to the group's Forum section</li>
<li>Click \"New Topic\"</li>
<li>Enter a descriptive title</li>
<li>Write your message using the text editor</li>
<li>Select the appropriate category</li>
<li>Add tags to improve searchability</li>
<li>Submit the topic</li>
</ol>

<h3>Discussion Moderation Tools</h3>
<p>Group admins and moderators can:</p>
<ul>
<li>Sticky important topics to keep them at the top</li>
<li>Close topics that have reached a resolution</li>
<li>Split topics if conversations diverge</li>
<li>Merge related topics</li>
<li>Edit or delete inappropriate content</li>
</ul>

<h3>Encouraging Healthy Discussions</h3>
<ol>
<li>Create a \"Welcome\" or \"Start Here\" topic with group rules</li>
<li>Ask open-ended questions to stimulate conversation</li>
<li>Recognize and thank active contributors</li>
<li>Summarize long discussions periodically</li>
<li>Use polls to gather opinions on important topics</li>
</ol>

<h3>Handling Challenging Situations</h3>
<ul>
<li>Address conflicts promptly and privately when possible</li>
<li>Be clear about which community guidelines were violated</li>
<li>Focus on behaviors rather than personalities</li>
<li>Provide warnings before taking stronger actions</li>
</ul>

<p>In the next tutorial, we'll explore how to expand your group's capabilities with additional features.</p>|$groups_cat_id|2"
        
        "Organizing Group Events|<h2>Planning Activities with BuddyPress Group Events</h2>
<p>Events bring community members together for real-time engagement. This tutorial explains how to create and manage events within BuddyPress groups.</p>

<h3>Adding Events Functionality</h3>
<p>BuddyPress doesn't include events by default. You'll need a compatible plugin:</p>
<ol>
<li>Install and activate an events plugin like \"BuddyPress Group Events\" or \"Events Manager\"</li>
<li>Configure the plugin settings to work with BuddyPress groups</li>
<li>Enable the Events feature in your group settings</li>
</ol>

<h3>Creating a Group Event</h3>
<ol>
<li>Navigate to your group's Events section</li>
<li>Click \"Add New Event\"</li>
<li>Enter the event title and description</li>
<li>Set the date, time, and duration</li>
<li>Specify the location (physical or virtual)</li>
<li>Add event categories and tags</li>
<li>Upload an event image</li>
<li>Set attendance limits if needed</li>
<li>Configure RSVP options</li>
<li>Publish the event</li>
</ol>

<h3>Managing Event RSVPs</h3>
<p>Track attendance with these features:</p>
<ul>
<li>View the list of attendees</li>
<li>Send messages to registered participants</li>
<li>Export attendee information</li>
<li>Set up waitlists for popular events</li>
<li>Track attendance statistics</li>
</ul>

<h3>Promoting Group Events</h3>
<ol>
<li>Post announcements in the group activity stream</li>
<li>Send direct invitations to relevant members</li>
<li>Create reminder posts as the event approaches</li>
<li>Share the event on main site activity if appropriate</li>
<li>Consider email notifications for important updates</li>
</ol>

<h3>Virtual and Hybrid Events</h3>
<p>For online gatherings:</p>
<ul>
<li>Include clear instructions for accessing virtual platforms</li>
<li>Test technology in advance</li>
<li>Provide alternatives for participation</li>
<li>Consider recording sessions for those who can't attend</li>
<li>Gather feedback to improve future events</li>
</ul>

<h3>Post-Event Follow-up</h3>
<ol>
<li>Thank participants for attending</li>
<li>Share highlights, photos, or recordings</li>
<li>Create a discussion thread for continuing conversations</li>
<li>Collect feedback through surveys</li>
<li>Announce upcoming events while interest is high</li>
</ol>

<p>In the next tutorial, we'll explore how to effectively grow your group membership.</p>|$groups_cat_id|3"
    )
    
    # Member Management Tutorials
    members_tutorials=(
        "Managing Membership Requests|<h2>Handling Membership in Your BuddyPress Community</h2>
<p>This tutorial explains how to effectively manage user registrations and membership requests for your BuddyPress site and groups.</p>

<h3>Site Registration Settings</h3>
<p>Configure who can join your community:</p>
<ol>
<li>Go to Settings > General in your WordPress admin</li>
<li>Set \"Membership\" to allow or disallow new registrations</li>
<li>Go to BuddyPress > Settings to configure BuddyPress-specific options</li>
<li>Consider requiring email activation for new accounts</li>
</ol>

<h3>Custom Registration Fields</h3>
<p>Gather relevant information during registration:</p>
<ol>
<li>Go to Users > Profile Fields</li>
<li>Create a field group for registration (e.g., \"Signup Information\")</li>
<li>Add fields and mark them as \"Required at Registration\"</li>
<li>Consider adding a Terms & Conditions acceptance checkbox</li>
</ol>

<h3>Managing Group Membership Requests</h3>
<p>For private groups, handle join requests:</p>
<ol>
<li>Go to the group's admin area</li>
<li>Select \"Requests\" to see pending requests</li>
<li>Review each request (profile, message if included)</li>
<li>Accept or reject requests with appropriate messaging</li>
</ol>

<h3>Creating a Membership Approval Workflow</h3>
<p>For sites requiring manual approval:</p>
<ol>
<li>Install a membership approval plugin (e.g., \"BP Registration Options\")</li>
<li>Configure the approval process</li>
<li>Create standard criteria for approving members</li>
<li>Set up email templates for approval/rejection</li>
</ol>

<h3>Bulk Member Management</h3>
<ul>
<li>Filter members by role, activity date, or profile data</li>
<li>Perform bulk actions (add to group, change role, etc.)</li>
<li>Send announcements to specific member segments</li>
</ul>

<h3>Handling Problematic Members</h3>
<ol>
<li>Create clear community guidelines</li>
<li>Use a graduated response system:
  <ul>
    <li>Private message for first offenses</li>
    <li>Temporary suspension for repeated issues</li>
    <li>Permanent ban for serious violations</li>
  </ul>
</li>
<li>Document incidents and actions taken</li>
<li>Consider having an appeals process</li>
</ol>

<p>In the next tutorial, we'll explore how to encourage positive communication between members.</p>|$members_cat_id|1"
        
        "Setting Up Friendship Connections|<h2>Building Relationships with BuddyPress Connections</h2>
<p>The Connections (Friends) component allows members to create a network of relationships within your community. This tutorial explains how to set up and manage this feature.</p>

<h3>Enabling the Connections Component</h3>
<ol>
<li>Go to BuddyPress > Components in your WordPress admin</li>
<li>Activate the \"Member Connections\" component</li>
<li>Save your changes</li>
</ol>

<h3>Customizing Connection Settings</h3>
<p>Configure how connections work:</p>
<ol>
<li>Go to BuddyPress > Settings</li>
<li>Scroll to the Connections section</li>
<li>Set options such as:
  <ul>
    <li>Allow friendship cancellations</li>
    <li>Connection button text (\"Add Friend\" vs. \"Connect\" etc.)</li>
    <li>Connection request notification settings</li>
  </ul>
</li>
</ol>

<h3>Creating Connections as a User</h3>
<p>Explain to your members how to:</p>
<ol>
<li>Visit another member's profile</li>
<li>Click the \"Add Friend\" or \"Connect\" button</li>
<li>Add a personal message with the request (if enabled)</li>
<li>Wait for acceptance</li>
<li>Manage pending requests from the Connections tab</li>
</ol>

<h3>Connection Visibility Options</h3>
<p>Control who can see member connections:</p>
<ul>
<li>Go to BuddyPress > Settings > Visibility</li>
<li>Configure who can see a user's connections:
  <ul>
    <li>Everyone</li>
    <li>Logged-in members only</li>
    <li>Only the user's connections</li>
    <li>Only the user themselves</li>
  </ul>
</li>
</ul>

<h3>Leveraging Connections for Community Building</h3>
<ol>
<li>Show mutual connections to help users find relevant people</li>
<li>Use connection counts as reputation indicators</li>
<li>Recommend potential connections based on groups or interests</li>
<li>Create exclusive content or features for members with connected status</li>
</ol>

<h3>Managing Connection Issues</h3>
<ul>
<li>Help users block unwanted connection requests</li>
<li>Provide guidance for gracefully declining requests</li>
<li>Create protocols for reporting harassment through connection features</li>
<li>Monitor for unusual connection patterns that may indicate spam accounts</li>
</ul>

<p>In the next tutorial, we'll explore how to implement and manage private messaging between members.</p>|$members_cat_id|2"
        
        "Implementing Private Messaging|<h2>Facilitating Member Communication with BuddyPress Messages</h2>
<p>Private messaging allows members to communicate directly and privately. This tutorial covers how to set up and manage the messaging system in BuddyPress.</p>

<h3>Enabling the Messages Component</h3>
<ol>
<li>Go to BuddyPress > Components in your WordPress admin</li>
<li>Activate the \"Private Messaging\" component</li>
<li>Save your changes</li>
</ol>

<h3>Configuring Message Settings</h3>
<p>Customize the messaging experience:</p>
<ol>
<li>Go to BuddyPress > Settings</li>
<li>Scroll to the Messages section</li>
<li>Configure options such as:
  <ul>
    <li>Auto-suggest recipients when composing</li>
    <li>Allow message threading vs. individual messages</li>
    <li>Set message notification preferences</li>
    <li>Configure per-user message limits (if needed)</li>
  </ul>
</li>
</ol>

<h3>Setting Up Message Permissions</h3>
<p>Control who can message whom:</p>
<ul>
<li>Allow all members to message anyone</li>
<li>Restrict messaging to connected members only</li>
<li>Create role-based messaging restrictions</li>
<li>Consider plugins for additional control over messaging permissions</li>
</ul>

<h3>Creating Admin Announcements</h3>
<p>The messaging system can be used for site-wide communication:</p>
<ol>
<li>Install a mass messaging plugin (e.g., \"BP Mass Messaging\")</li>
<li>Compose your announcement</li>
<li>Select recipient groups (all users, specific roles, etc.)</li>
<li>Schedule or send immediately</li>
<li>Track read receipts if available</li>
</ol>

<h3>Message Moderation and Spam Control</h3>
<ul>
<li>Implement message content filtering for inappropriate content</li>
<li>Set rate limits to prevent message flooding</li>
<li>Create a reporting system for problematic messages</li>
<li>Consider pre-moderation for new or flagged users</li>
</ul>

<h3>User Interface Enhancements</h3>
<p>Improve the messaging experience:</p>
<ul>
<li>Add emoji support</li>
<li>Enable file attachments (with appropriate security measures)</li>
<li>Implement real-time notifications for new messages</li>
<li>Consider AJAX-based interfaces for smoother user experience</li>
</ul>

<p>In the next tutorial, we'll explore how to effectively manage user roles and permissions.</p>|$members_cat_id|3"
    )
    
    # Activity Streams Tutorials
    activity_tutorials=(
        "Understanding the Activity Stream|<h2>Mastering the BuddyPress Activity Component</h2>
<p>The activity stream is the pulse of your BuddyPress community. This tutorial explains how it works and how to configure it effectively.</p>

<h3>What is the Activity Stream?</h3>
<p>The activity stream displays chronological updates about actions across your community, including:</p>
<ul>
<li>Status updates from members</li>
<li>New friendships and connections</li>
<li>Group creations and activities</li>
<li>Blog post publications</li>
<li>Profile updates</li>
<li>Forum discussions</li>
</ul>

<h3>Types of Activity Streams</h3>
<p>BuddyPress provides several activity views:</p>
<ol>
<li><strong>Sitewide Activity</strong>: All activity across the community</li>
<li><strong>Personal Activity</strong>: A member's own activities</li>
<li><strong>Friends Activity</strong>: Updates from connected members</li>
<li><strong>Group Activity</strong>: Updates from specific groups</li>
<li><strong>Mentions</strong>: Activities where a user is mentioned</li>
<li><strong>Favorites</strong>: Activities a user has marked as favorite</li>
</ol>

<h3>Configuring Activity Settings</h3>
<ol>
<li>Go to BuddyPress > Settings > Activity</li>
<li>Choose which actions generate activity items</li>
<li>Set activity display preferences</li>
<li>Configure comment and reply settings</li>
<li>Set up moderation options if needed</li>
</ol>

<h3>Activity Privacy and Scope</h3>
<p>Control who sees what activities:</p>
<ul>
<li>Public vs. member-only activity visibility</li>
<li>Group-specific activity privacy settings</li>
<li>User-level privacy controls for status updates</li>
<li>Role-based activity visibility restrictions</li>
</ul>

<h3>Activity Interactions</h3>
<p>Members can engage with activity items:</p>
<ul>
<li>Like/favorite updates</li>
<li>Comment on activities</li>
<li>Share or repost (if enabled)</li>
<li>Mention other users with @username</li>
<li>Add hashtags for topic categorization</li>
</ul>

<h3>Extending Activity Functionality</h3>
<p>Consider these enhancements:</p>
<ul>
<li>Rich media embeds (videos, images, links)</li>
<li>Activity filtering by type</li>
<li>Hashtag support and trending topics</li>
<li>Activity pinning for important announcements</li>
<li>Advanced notification options</li>
</ul>

<p>In the next tutorial, we'll explore activity moderation and keeping your community healthy.</p>|$activity_cat_id|1"
        
        "Posting and Interacting with Updates|<h2>Creating Engaging Content in Your BuddyPress Community</h2>
<p>This tutorial covers how members can effectively post updates and interact with content in the activity stream.</p>

<h3>Posting Status Updates</h3>
<ol>
<li>Navigate to the activity stream or profile</li>
<li>Locate the update form (\"What's new?\" or similar text)</li>
<li>Compose your update in the text area</li>
<li>Add formatting if supported (bold, italic, etc.)</li>
<li>Set privacy level if available (public, friends, etc.)</li>
<li>Click \"Post Update\" to publish</li>
</ol>

<h3>Enhancing Updates with Media</h3>
<p>Create richer updates with:</p>
<ul>
<li>Photos and images</li>
<li>Videos (embedded or uploaded)</li>
<li>Links with automatic previews</li>
<li>Documents and files</li>
<li>Polls and surveys (with additional plugins)</li>
</ul>

<h3>Using Mentions and Hashtags</h3>
<p>Connect your content to people and topics:</p>
<ul>
<li>Mention users with @username to notify them</li>
<li>Create hashtags with #topic to categorize content</li>
<li>Use hashtags consistently for ongoing discussions</li>
<li>Search for hashtags to find related content</li>
</ul>

<h3>Commenting and Replying</h3>
<ol>
<li>Click the \"Comment\" link below an activity item</li>
<li>Enter your comment in the text field</li>
<li>Use @mentions to direct comments to specific users</li>
<li>Reply to specific comments when threading is enabled</li>
<li>Edit or delete your comments if needed</li>
</ol>

<h3>Using Reactions and Favorites</h3>
<ul>
<li>Click the \"Like\" or reaction button to show appreciation</li>
<li>Use the \"Favorite\" option to save items for later reference</li>
<li>View your favorites list from your profile</li>
<li>Understand that reactions may be visible to others</li>
</ul>

<h3>Activity Etiquette Guidelines</h3>
<ol>
<li>Keep updates relevant to the community's purpose</li>
<li>Be respectful in comments and replies</li>
<li>Avoid excessive posting or spammy behavior</li>
<li>Use appropriate content warnings when needed</li>
<li>Respect privacy settings and boundaries</li>
</ol>

<p>In the next tutorial, we'll explore how to effectively moderate activity content.</p>|$activity_cat_id|2"
        
        "Moderating Activity Content|<h2>Maintaining a Healthy Activity Stream</h2>
<p>This tutorial explains how to effectively moderate content in your BuddyPress activity stream to ensure a positive community experience.</p>

<h3>Setting Up Moderation Systems</h3>
<ol>
<li>Establish clear community guidelines</li>
<li>Create a moderation team with defined roles</li>
<li>Install moderation plugins like:
  <ul>
    <li>BuddyPress Moderation</li>
    <li>BadgeOS for positive reinforcement</li>
    <li>Block, Suspend, Report for member management</li>
  </ul>
</li>
<li>Configure automatic content filtering</li>
</ol>

<h3>Content Filtering Options</h3>
<p>Control problematic content with:</p>
<ul>
<li>Word filters for profanity and prohibited terms</li>
<li>Spam detection algorithms</li>
<li>Link restrictions to prevent malicious URLs</li>
<li>Attachment scanning for malware</li>
<li>Rate limiting to prevent flooding</li>
</ul>

<h3>Manual Moderation Actions</h3>
<p>Moderators can take these actions:</p>
<ol>
<li>Hide/delete inappropriate updates or comments</li>
<li>Issue warnings to members</li>
<li>Temporarily suspend posting privileges</li>
<li>Ban repeat offenders</li>
<li>Document incidents for reference</li>
</ol>

<h3>Implementing a Reporting System</h3>
<ol>
<li>Add a \"Report\" button to activity items</li>
<li>Create a reporting form with reason categories</li>
<li>Set up notifications for moderators</li>
<li>Establish a review workflow for reports</li>
<li>Provide feedback to users who submit reports</li>
</ol>

<h3>Pre-Moderation for New Members</h3>
<ul>
<li>Consider approving first posts from new accounts</li>
<li>Implement a probation period for new members</li>
<li>Gradually increase posting privileges based on trust</li>
<li>Use captchas or verification for new accounts</li>
</ul>

<h3>Creating a Positive Culture</h3>
<ol>
<li>Lead by example with moderator content</li>
<li>Highlight exemplary community contributions</li>
<li>Publicly acknowledge helpful members</li>
<li>Create a recognition system for valuable participation</li>
<li>Provide constructive feedback rather than just punishment</li>
</ol>

<p>In the next tutorial, we'll explore how to customize activity notifications to keep members engaged.</p>|$activity_cat_id|3"
    )
    
    # BuddyX Theme Tutorials
    buddyx_tutorials=(
        "Introduction to BuddyX Theme|<h2>Getting Started with BuddyX</h2>
<p>BuddyX is a powerful theme designed specifically for BuddyPress communities. This tutorial introduces its key features and basic setup.</p>

<h3>What is BuddyX?</h3>
<p>BuddyX is a responsive WordPress theme built to enhance BuddyPress-powered social networks with:</p>
<ul>
<li>Modern, clean design optimized for community engagement</li>
<li>Seamless BuddyPress integration with enhanced styling</li>
<li>Flexible layout options for various community types</li>
<li>Performance optimization for busy communities</li>
<li>Mobile-first responsive design</li>
</ul>

<h3>Installing BuddyX</h3>
<ol>
<li>Go to Appearance > Themes > Add New in your WordPress admin</li>
<li>Search for \"BuddyX\"</li>
<li>Click \"Install\" and then \"Activate\"</li>
<li>Alternatively, download from WordPress.org and upload via the theme installer</li>
</ol>

<h3>Initial Theme Setup</h3>
<ol>
<li>Go to Appearance > Customize</li>
<li>Browse through the customization panels:
  <ul>
    <li>Site Identity (logo, title, tagline)</li>
    <li>Colors and Typography</li>
    <li>Layout Options</li>
    <li>Header and Navigation</li>
    <li>BuddyPress Settings</li>
    <li>Footer Options</li>
  </ul>
</li>
<li>Make initial adjustments to match your brand</li>
<li>Save changes</li>
</ol>

<h3>Key Features of BuddyX</h3>
<ul>
<li><strong>Community-focused layouts</strong>: Optimized for member interaction</li>
<li><strong>Activity stream enhancements</strong>: Improved readability and engagement</li>
<li><strong>Profile layouts</strong>: Modern, clean member profiles</li>
<li><strong>Group customizations</strong>: Better group navigation and content organization</li>
<li><strong>Dark mode support</strong>: Reduces eye strain for night browsing</li>
<li><strong>Header variations</strong>: Multiple header layouts to choose from</li>
</ul>

<h3>BuddyX vs. Standard BuddyPress Themes</h3>
<p>Advantages of BuddyX over default themes:</p>
<ul>
<li>Modern social network aesthetic vs. basic designs</li>
<li>More customization options without coding</li>
<li>Better mobile experience</li>
<li>Improved navigation for community features</li>
<li>Enhanced performance optimization</li>
</ul>

<p>In the next tutorial, we'll explore how to customize BuddyX to match your brand identity.</p>|$buddyx_cat_id|1"
        
        "Customizing BuddyX Appearance|<h2>Styling Your BuddyX-Powered Community</h2>
<p>This tutorial walks through the process of customizing BuddyX to create a unique and branded community experience.</p>

<h3>Using the WordPress Customizer</h3>
<ol>
<li>Go to Appearance > Customize</li>
<li>Browse available customization sections</li>
<li>Make changes and preview in real-time</li>
<li>Save when satisfied with the results</li>
</ol>

<h3>Brand Identity Elements</h3>
<p>Establish your community's visual identity:</p>
<ol>
<li>Upload your logo in Site Identity</li>
<li>Set a site icon (favicon)</li>
<li>Configure your primary and accent colors</li>
<li>Choose fonts that reflect your brand personality</li>
<li>Add a custom login page background</li>
</ol>

<h3>Layout Customization</h3>
<ul>
<li>Container width for content areas</li>
<li>Sidebar positioning (left, right, none)</li>
<li>Page header styles</li>
<li>Content spacing adjustments</li>
<li>Archive and blog layout options</li>
</ul>

<h3>Header and Navigation Options</h3>
<ol>
<li>Select header layout style:
  <ul>
    <li>Standard header</li>
    <li>Community header (with BuddyPress menus)</li>
    <li>Fixed header for easy navigation</li>
  </ul>
</li>
<li>Configure menu positions</li>
<li>Set up mobile navigation options</li>
<li>Customize login/register buttons</li>
</ol>

<h3>BuddyPress-Specific Styling</h3>
<p>Enhance your community areas:</p>
<ul>
<li>Activity stream layout and design</li>
<li>Member directory appearance</li>
<li>Group directory and single group pages</li>
<li>Profile tabs and layout</li>
<li>Message system styling</li>
</ul>

<h3>Advanced Customization</h3>
<p>For deeper customization:</p>
<ol>
<li>Use the Additional CSS section in Customizer</li>
<li>Create a child theme for code modifications</li>
<li>Utilize theme hooks for PHP customizations</li>
<li>Consider custom page templates for special sections</li>
</ol>

<h3>Mobile Responsiveness</h3>
<ul>
<li>Preview your site in mobile view within Customizer</li>
<li>Ensure menus collapse properly on small screens</li>
<li>Check readability of text at all screen sizes</li>
<li>Verify touch targets are large enough for mobile users</li>
</ul>

<p>In the next tutorial, we'll explore BuddyX's performance optimization features.</p>|$buddyx_cat_id|2"
        
        "BuddyX Performance Optimization|<h2>Speeding Up Your BuddyX Community</h2>
<p>This tutorial explains how to optimize the performance of your BuddyX-powered BuddyPress community for a faster, smoother user experience.</p>

<h3>Why Performance Matters</h3>
<p>Fast-loading communities provide several benefits:</p>
<ul>
<li>Improved user satisfaction and engagement</li>
<li>Higher retention rates</li>
<li>Better search engine rankings</li>
<li>Reduced server load and costs</li>
<li>Better mobile experience</li>
</ul>

<h3>BuddyX Performance Features</h3>
<p>The theme includes several optimization features:</p>
<ol>
<li>Lightweight code structure</li>
<li>Optimized CSS and JavaScript loading</li>
<li>Selective component loading</li>
<li>Efficient template system</li>
<li>Pagination options to reduce initial load</li>
</ol>

<h3>Optimizing Images</h3>
<ul>
<li>Configure image sizes in BuddyX settings</li>
<li>Use appropriate image compression</li>
<li>Implement lazy loading for activity stream images</li>
<li>Consider WebP format for better compression</li>
<li>Set reasonable limits for user uploads</li>
</ul>

<h3>Caching Configuration</h3>
<ol>
<li>Enable compatible caching plugins</li>
<li>Configure BuddyPress-specific cache settings</li>
<li>Use object caching if available on your host</li>
<li>Implement browser caching for static assets</li>
<li>Configure exclusions for dynamic community content</li>
</ol>

<h3>Database Optimization</h3>
<ul>
<li>Regular database cleanup for BuddyPress tables</li>
<li>Optimize activity and notification tables</li>
<li>Consider external object cache for query results</li>
<li>Implement efficient queries for custom functionality</li>
</ul>

<h3>Content Delivery and Hosting</h3>
<ol>
<li>Use a CDN for static assets</li>
<li>Choose hosting optimized for WordPress and BuddyPress</li>
<li>Consider dedicated hosting for larger communities</li>
<li>Implement GZIP compression</li>
<li>Use HTTP/2 or HTTP/3 if available</li>
</ol>

<h3>Measuring Performance</h3>
<ul>
<li>Use tools like GTmetrix or PageSpeed Insights</li>
<li>Monitor real user metrics</li>
<li>Set up performance budgets</li>
<li>Regular testing across devices</li>
<li>A/B test performance optimizations</li>
</ul>

<p>In the next tutorial, we'll explore how to extend BuddyX with custom functionality.</p>|$buddyx_cat_id|3"
    )
    
    # Function to create tutorial posts
    create_tutorial_post() {
        local data="$1"
        
        # Split the data into variables
        IFS='|' read -r title content category_id order <<< "$data"
        
        # Select a random user as the author (excluding admin)
        author_id=$((RANDOM % 10 + 2))
        if ! wp user get $author_id --path=/var/www/html &>/dev/null; then
            author_id=1
        fi
        
        # Get author name for display in post content
        author_name=$(wp user get $author_id --field=display_name --path=/var/www/html)
        
        # Add author attribution to content
        content+="<p class=\"author-attribution\"><em>Written by $author_name</em></p>"
        
        # Create the post
        post_id=$(wp post create --post_title="$title" --post_content="$content" --post_status="publish" --post_type="post" --post_author="$author_id" --porcelain --path=/var/www/html)
        
        # Assign the category after creation to avoid issues
        wp post term add "$post_id" category "$category_id" --path=/var/www/html
        
        # Set menu order for proper sorting
        wp post update "$post_id" --menu_order="$order" --path=/var/www/html
        
        echo "Created tutorial post ID: $post_id - $title (by $author_name)"
    }
    
    echo "Creating BuddyPress basics tutorials..."
    for tutorial in "${basics_tutorials[@]}"; do
        create_tutorial_post "$tutorial"
    done
    
    echo "Creating group management tutorials..."
    for tutorial in "${groups_tutorials[@]}"; do
        create_tutorial_post "$tutorial"
    done
    
    echo "Creating member management tutorials..."
    for tutorial in "${members_tutorials[@]}"; do
        create_tutorial_post "$tutorial"
    done
    
    echo "Creating activity stream tutorials..."
    for tutorial in "${activity_tutorials[@]}"; do
        create_tutorial_post "$tutorial"
    done
    
    echo "Creating BuddyX theme tutorials..."
    for tutorial in "${buddyx_tutorials[@]}"; do
        create_tutorial_post "$tutorial"
    done
    
    # Create a course curriculum page that lists and links to all tutorials
    echo "Creating course curriculum page..."
    
    curriculum_content="<h1>BuddyPress & BuddyX Social Network Tutorial Series</h1>
<p>Welcome to our comprehensive tutorial series on building social networks with WordPress, BuddyPress, and the BuddyX theme. This curriculum will guide you through everything you need to know to create and manage a thriving online community.</p>

<h2>Getting Started with BuddyPress</h2>
<ul>"

    # Add basics tutorials
    for tutorial in "${basics_tutorials[@]}"; do
        IFS='|' read -r title content category_id order <<< "$tutorial"
        # Get the post ID more reliably by title
        post_id=$(wp post list --post_type=post --post_status=publish --title="$title" --field=ID --path=/var/www/html)
        if [ -n "$post_id" ]; then
            curriculum_content+="<li><a href=\"$(wp post get $post_id --field=guid --path=/var/www/html)\">$title</a></li>"
        else
            curriculum_content+="<li>$title</li>"
        fi
    done

    curriculum_content+="</ul>

<h2>Group Management</h2>
<ul>"

    # Add group management tutorials
    for tutorial in "${groups_tutorials[@]}"; do
        IFS='|' read -r title content category_id order <<< "$tutorial"
        # Get the post ID more reliably by title
        post_id=$(wp post list --post_type=post --post_status=publish --title="$title" --field=ID --path=/var/www/html)
        if [ -n "$post_id" ]; then
            curriculum_content+="<li><a href=\"$(wp post get $post_id --field=guid --path=/var/www/html)\">$title</a></li>"
        else
            curriculum_content+="<li>$title</li>"
        fi
    done

    curriculum_content+="</ul>

<h2>Member Management</h2>
<ul>"

    # Add member management tutorials
    for tutorial in "${members_tutorials[@]}"; do
        IFS='|' read -r title content category_id order <<< "$tutorial"
        # Get the post ID more reliably by title
        post_id=$(wp post list --post_type=post --post_status=publish --title="$title" --field=ID --path=/var/www/html)
        if [ -n "$post_id" ]; then
            curriculum_content+="<li><a href=\"$(wp post get $post_id --field=guid --path=/var/www/html)\">$title</a></li>"
        else
            curriculum_content+="<li>$title</li>"
        fi
    done

    curriculum_content+="</ul>

<h2>Activity Streams</h2>
<ul>"

    # Add activity stream tutorials
    for tutorial in "${activity_tutorials[@]}"; do
        IFS='|' read -r title content category_id order <<< "$tutorial"
        # Get the post ID more reliably by title
        post_id=$(wp post list --post_type=post --post_status=publish --title="$title" --field=ID --path=/var/www/html)
        if [ -n "$post_id" ]; then
            curriculum_content+="<li><a href=\"$(wp post get $post_id --field=guid --path=/var/www/html)\">$title</a></li>"
        else
            curriculum_content+="<li>$title</li>"
        fi
    done

    curriculum_content+="</ul>

<h2>BuddyX Theme</h2>
<ul>"

    # Add BuddyX theme tutorials
    for tutorial in "${buddyx_tutorials[@]}"; do
        IFS='|' read -r title content category_id order <<< "$tutorial"
        # Get the post ID more reliably by title
        post_id=$(wp post list --post_type=post --post_status=publish --title="$title" --field=ID --path=/var/www/html)
        if [ -n "$post_id" ]; then
            curriculum_content+="<li><a href=\"$(wp post get $post_id --field=guid --path=/var/www/html)\">$title</a></li>"
        else
            curriculum_content+="<li>$title</li>"
        fi
    done

    curriculum_content+="</ul>

<h2>Additional Resources</h2>
<ul>
<li><a href=\"https://codex.buddypress.org/\" target=\"_blank\">BuddyPress Codex</a></li>
<li><a href=\"https://wordpress.org/plugins/buddypress/\" target=\"_blank\">BuddyPress Plugin Page</a></li>
<li><a href=\"https://wbcomdesigns.com/downloads/buddyx-theme/\" target=\"_blank\">BuddyX Theme Documentation</a></li>
</ul>

<p>This course curriculum is designed to be followed sequentially, but feel free to jump to specific tutorials that address your immediate needs. Happy community building!</p>"

    # Create the curriculum page
    curriculum_page_id=$(wp post create --post_type=page --post_title="Tutorial Course Curriculum" --post_content="$curriculum_content" --post_status="publish" --path=/var/www/html --porcelain)
    
    echo "Created tutorial curriculum page with ID: $curriculum_page_id"
    
    # Add the curriculum page to the main menu if menus exist
    if wp menu list --path=/var/www/html &>/dev/null; then
        main_menu=$(wp menu list --format=ids --path=/var/www/html | head -n1)
        if [ -n "$main_menu" ]; then
            wp menu item add-post $main_menu $curriculum_page_id --path=/var/www/html
            echo "Added curriculum page to main menu"
        fi
    fi
# endregion: TUTORIAL CONTENT

echo "Data population completed!"