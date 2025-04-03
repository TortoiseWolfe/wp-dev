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

# Set permalink structure EARLY for better URLs
echo "Setting permalink structure..."
# Just use the simplest method possible
wp option update permalink_structure '/%postname%/' --path=/var/www/html
wp rewrite flush --path=/var/www/html
# Check permalink structure
echo "Verifying permalink structure..."
wp option get permalink_structure --path=/var/www/html

# Make sure we have a useful message for the user
echo "NOTE: While tutorial content is created using markdown format, the links in the curriculum page will work correctly with pretty URLs."

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

echo "Setting up post categories..."
# Categories for posts
categories=(
    "Philosophy" 
    "Literature"
    "History"
    "Classical Studies"
    "Roman Culture"
)

# Create categories if they don't exist and store their IDs
category_ids=()
for category in "${categories[@]}"; do
    # Generate a proper slug from the category name
    slug=$(echo "$category" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    
    # Check if category exists
    existing_cat_id=$(wp term list category --name="$category" --field=term_id --path=/var/www/html)
    
    if [ -n "$existing_cat_id" ]; then
        # Use existing category
        cat_id=$existing_cat_id
        echo "Using existing category: $category with ID: $cat_id"
    else
        # Create new category
        cat_id=$(wp term create category "$category" --slug="$slug" --porcelain --path=/var/www/html)
        echo "Created category: $category with ID: $cat_id and slug: $slug"
    fi
    
    category_ids+=("$cat_id")
done

echo "Creating example posts..."
# Create 20 example posts randomly assigned to different users and categories
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
    
    # Assign a random category to the post
    rand_category_index=$((RANDOM % ${#category_ids[@]}))
    category_id=${category_ids[$rand_category_index]}
    
    # Create the post with the category directly to avoid "Uncategorized" being added
    post_id=$(wp post create --post_title="$title" --post_content="$content" --post_status="publish" --post_author="$user_id" --post_category="$category_id" --porcelain --path=/var/www/html)
    
    # Remove Uncategorized category if still assigned
    wp post term remove "$post_id" category 1 --path=/var/www/html || true
    
    echo "Created post ID: $post_id by user ID: $user_id in category: ${categories[$rand_category_index]}"
    
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

# If BuddyPress is active, create groups
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

# region: TUTORIAL CONTENT CREATION
echo "Creating tutorial content for BuddyPress and BuddyX..."

# Permalinks already set at beginning of script

# Create main tutorial category and subcategories first so we have the IDs
echo "Creating tutorial categories..."
main_cat_id=$(wp term create category "BuddyPress Tutorials" --slug="buddypress-tutorials" --porcelain --path=/var/www/html)
echo "Created main tutorial category with ID: $main_cat_id"

# Create subcategories
getting_started_id=$(wp term create category "Getting Started" --slug="getting-started" --parent=$main_cat_id --porcelain --path=/var/www/html)
echo "Created 'Getting Started' subcategory with ID: $getting_started_id"

group_management_id=$(wp term create category "Group Management" --slug="group-management" --parent=$main_cat_id --porcelain --path=/var/www/html)
echo "Created 'Group Management' subcategory with ID: $group_management_id"

member_management_id=$(wp term create category "Member Management" --slug="member-management" --parent=$main_cat_id --porcelain --path=/var/www/html)
echo "Created 'Member Management' subcategory with ID: $member_management_id"

activity_streams_id=$(wp term create category "Activity Streams" --slug="activity-streams" --parent=$main_cat_id --porcelain --path=/var/www/html)
echo "Created 'Activity Streams' subcategory with ID: $activity_streams_id"

buddyx_theme_id=$(wp term create category "BuddyX Theme" --slug="buddyx-theme" --parent=$main_cat_id --porcelain --path=/var/www/html)
echo "Created 'BuddyX Theme' subcategory with ID: $buddyx_theme_id"

# IMPORTANT: Use plugin-based gamification system ONLY - do not add gamification code directly to posts
echo "Preparing to create tutorial content (gamification will be handled by plugin only)..."

# Remove any gamification variables that would cause duplication
TUTORIAL_GAMIFICATION_HEADER=""
TUTORIAL_GAMIFICATION_FOOTER=""
INCOMPLETE_TUTORIAL_FOOTER=""

# Create tutorial posts
echo "Creating tutorial posts with gamification elements..."

# Getting Started tutorials
intro_bp_id=$(wp post create --post_title="Introduction to BuddyPress" --post_name="introduction-to-buddypress" --post_author="1" --post_date="2025-03-26 10:00:00" --post_content="<h2>Introduction to BuddyPress</h2>

<p>BuddyPress is a powerful plugin that transforms your WordPress site into a full-featured social network. It allows your users to connect with each other, create groups, post status updates, and much more.</p>

<h3>What is BuddyPress?</h3>

<p>BuddyPress is often described as 'social networking in a box.' It provides all the core features you would expect from a social platform:</p>

<ul>
<li><strong>Member Profiles</strong>: Customizable user profiles</li>
<li><strong>Activity Streams</strong>: Real-time updates of user activities</li>
<li><strong>User Groups</strong>: Allow users to create and join groups</li>
<li><strong>Private Messaging</strong>: Direct communication between users</li>
<li><strong>Friend Connections</strong>: Users can connect with each other</li>
<li><strong>Notifications</strong>: Keep users informed about relevant activities</li>
</ul>

<h3>Why Use BuddyPress?</h3>

<ul>
<li><strong>Open Source</strong>: Free to use and modify</li>
<li><strong>WordPress Integration</strong>: Seamlessly works with WordPress</li>
<li><strong>Extensible</strong>: Many plugins specifically designed for BuddyPress</li>
<li><strong>Community-Driven</strong>: Active development and support community</li>
<li><strong>Customizable</strong>: Adapt it to suit your specific community needs</li>
</ul>

<h3>BuddyPress Components</h3>

<p>BuddyPress is modular, allowing you to enable only the components you need:</p>

<ol>
<li><strong>Core</strong>: Essential functionality (always active)</li>
<li><strong>Members</strong>: User management and directories</li>
<li><strong>XProfile</strong>: Extended user profiles</li>
<li><strong>Activity</strong>: Activity streams</li>
<li><strong>Notifications</strong>: User notifications</li>
<li><strong>Messaging</strong>: Private user-to-user messaging</li>
<li><strong>Friends</strong>: Friend connections</li>
<li><strong>Groups</strong>: User groups</li>
<li><strong>Settings</strong>: User account settings</li>
<li><strong>Blogs</strong>: Multi-site blog tracking (for WordPress Multisite)</li>
</ol>

<p>In the next tutorial, we'll cover how to install and configure BuddyPress on your WordPress site.</p>

<!-- data-tutorial-slug=\"introduction-to-buddypress\" data-next-tutorial=\"installing-and-configuring-buddypress\" -->" --post_category=$getting_started_id --post_status=publish --porcelain --path=/var/www/html)
echo "Created 'Introduction to BuddyPress' tutorial with ID: $intro_bp_id"

install_bp_id=$(wp post create --post_title="Installing and Configuring BuddyPress" --post_name="installing-and-configuring-buddypress" --post_author="1" --post_date="2025-03-27 10:15:00" --post_content="
<h2>Installing and Configuring BuddyPress</h2>

<p>This tutorial guides you through the process of adding BuddyPress to your WordPress site and configuring its essential settings.</p>

<h3>Installation</h3>

<ol>
<li><strong>From WordPress Dashboard</strong>:
<ul>
<li>Go to Plugins &gt; Add New</li>
<li>Search for 'BuddyPress'</li>
<li>Click 'Install Now' and then 'Activate'</li>
</ul>
</li>
<li><strong>Manual Installation</strong>:
<ul>
<li>Download BuddyPress from WordPress.org</li>
<li>Upload the plugin folder to /wp-content/plugins/</li>
<li>Activate through the 'Plugins' menu</li>
</ul>
</li>
</ol>

<!-- wp:heading {\"level\":3} -->
<h3>Initial Setup</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>After activation, you'll see a 'BuddyPress' menu in your WordPress dashboard. Start by going to BuddyPress &gt; Components.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Configuring Components</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Select which components you want to activate:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li><strong>Core</strong>: (Required) The essential BuddyPress framework</li><li><strong>Members</strong>: User profiles and directories</li><li><strong>Extended Profiles</strong>: Custom profile fields</li><li><strong>Account Settings</strong>: User account management</li><li><strong>Activity Streams</strong>: Site-wide and user activity</li><li><strong>Notifications</strong>: User notifications system</li><li><strong>Friend Connections</strong>: Allow users to connect</li><li><strong>Private Messaging</strong>: User-to-user messages</li><li><strong>User Groups</strong>: Community groups functionality</li></ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>Begin with just the essential components, and add more as needed.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>BuddyPress Settings</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Go to Settings &gt; BuddyPress to configure:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li><strong>Main Settings</strong>:
<ul><li>Set roles that can bypass spam protection</li><li>Enable/disable @mentions functionality</li><li>Specify toolbar visibility</li></ul>
</li><li><strong>Registration Settings</strong>:
<ul><li>Enable/disable account activation emails</li><li>Allow custom profile fields during registration</li></ul>
</li><li><strong>Profile Settings</strong>:
<ul><li>Configure avatar settings</li><li>Set up profile visibility options</li></ul>
</li><li><strong>Groups Settings</strong> (if enabled):
<ul><li>Allow group creation by all members or admins only</li><li>Set default group visibility</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Page Setup</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyPress creates several pages automatically:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>Activity</li><li>Members</li><li>Register</li><li>Activate</li></ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>Verify these pages are created correctly in Pages &gt; All Pages.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Permalinks Configuration</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>For the best user experience:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to Settings &gt; Permalinks</li><li>Select 'Post name' as your permalink structure</li><li>Save Changes</li></ol>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>This optimizes URLs for BuddyPress content.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Testing Your Setup</h3>
<!-- /wp:heading -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Visit your site's homepage</li><li>Check navigation for BuddyPress links</li><li>Create a test user account</li><li>Explore different features as this user</li></ol>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>In the next tutorial, we'll explore how to customize member profiles to create a personalized experience for your community members.</p>
<!-- /wp:paragraph -->

<!-- data-tutorial-slug=\"installing-and-configuring-buddypress\" data-next-tutorial=\"customizing-member-profiles\" -->" --post_category=$getting_started_id --post_status=publish --porcelain --path=/var/www/html)
echo "Created 'Installing and Configuring BuddyPress' tutorial with ID: $install_bp_id"

profiles_bp_id=$(wp post create --post_title="Customizing Member Profiles" --post_name="customizing-member-profiles" --post_author="1" --post_date="2025-03-28 09:45:00" --post_content="
<!-- wp:heading -->
<h2>Customizing Member Profiles in BuddyPress</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Member profiles are at the heart of any social network. This tutorial will show you how to customize BuddyPress profiles to create a personalized experience for your community members.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Understanding Extended Profiles</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyPress's Extended Profiles (XProfile) component lets you create custom profile fields beyond what WordPress provides by default. These fields can collect various types of information from your members.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Enabling Extended Profiles</h3>
<!-- /wp:heading -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to BuddyPress &gt; Components</li><li>Ensure the 'Extended Profiles' component is active</li><li>Save changes</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Profile Field Types</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyPress offers several field types:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li><strong>Text Box</strong>: Single line of text</li><li><strong>Multi-Line Text Area</strong>: Multiple lines of text</li><li><strong>Date Selector</strong>: Calendar date picker</li><li><strong>Radio Buttons</strong>: Select one from multiple options</li><li><strong>Checkboxes</strong>: Select multiple options</li><li><strong>Drop Down Select Box</strong>: Dropdown menu of options</li><li><strong>Multi-Select Box</strong>: Select multiple options from a list</li><li><strong>URL</strong>: Website address field</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Creating Profile Field Groups</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Profile fields are organized into groups. To create a new group:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to Users &gt; Profile Fields</li><li>Click 'Add New Field Group'</li><li>Enter a name for the group (e.g., 'Personal Information')</li><li>Set the group description (optional)</li><li>Click 'Save'</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Adding Profile Fields</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>To add fields to a group:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Navigate to the field group</li><li>Click 'Add New Field'</li><li>Configure these settings:
<ul><li>Field Name: What to call the field</li><li>Field Description: Explanation for users</li><li>Field Type: Select from available types</li><li>Required?: Whether users must complete this field</li><li>Visibility: Who can see this information</li></ul>
</li><li>Click 'Save'</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Field Visibility Options</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyPress lets you set visibility levels for each field:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li><strong>Public</strong>: Visible to anyone</li><li><strong>All Members</strong>: Only visible to registered users</li><li><strong>Only Me</strong>: Private to the user</li><li><strong>My Friends</strong>: Only visible to connected friends</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Profile Field Order</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>You can change the order of profile fields:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to Users &gt; Profile Fields</li><li>Drag and drop fields within groups</li><li>Save changes</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Default Profile Fields</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyPress creates a 'Base' field group with a 'Name' field by default. These can't be deleted but can be customized.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Customizing the Profile Interface</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>To modify how profiles appear:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li><strong>Using a BuddyPress-compatible theme</strong> like BuddyX</li><li><strong>CSS customization</strong> for fine-tuning appearance</li><li><strong>BuddyPress template overrides</strong> for advanced customization</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Member Types</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>For more advanced profile categorization, you can create Member Types:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Using code in a custom plugin</li><li>Or using plugins like 'BP Member Types'</li></ol>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>This allows you to categorize users and provide different experiences.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Best Practices</h3>
<!-- /wp:heading -->

<!-- wp:list -->
<ul><li>Keep required fields to a minimum</li><li>Create logical field groupings</li><li>Provide clear field descriptions</li><li>Consider privacy implications</li><li>Test profiles on mobile devices</li></ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>In the next tutorial, we'll cover the BuddyPress interface and how users can navigate through your social network.</p>
<!-- /wp:paragraph -->

${TUTORIAL_GAMIFICATION_FOOTER/NEXT_TUTORIAL/creating-and-managing-groups}" --post_category=$getting_started_id --post_status=publish --porcelain --path=/var/www/html)
echo "Created 'Customizing Member Profiles' tutorial with ID: $profiles_bp_id"

# Group Management tutorial
groups_bp_id=$(wp post create --post_title="Creating and Managing Groups" --post_name="creating-and-managing-groups" --post_author="1" --post_date="2025-03-29 11:30:00" --post_content="<!-- wp:heading -->
<h2>Creating and Managing Groups in BuddyPress</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Groups are a powerful feature in BuddyPress that allow your community members to organize around shared interests. This tutorial covers everything you need to know about creating and managing groups.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Enabling Group Functionality</h3>
<!-- /wp:heading -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to BuddyPress &gt; Components</li><li>Ensure the 'User Groups' component is activated</li><li>Save your changes</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Group Types and Visibility</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyPress offers three types of groups:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li><strong>Public Groups</strong>: Visible to everyone, anyone can join</li><li><strong>Private Groups</strong>: Visible in directories, but joining requires approval</li><li><strong>Hidden Groups</strong>: Not listed in directories, members can only join by invitation</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Creating a Group as an Administrator</h3>
<!-- /wp:heading -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to Dashboard &gt; BuddyPress &gt; Groups</li><li>Click 'Add New'</li><li>Fill in the group details:
<ul><li>Name and description</li><li>Privacy settings</li><li>Enable/disable features (forum, photos, etc.)</li><li>Upload an avatar</li></ul>
</li><li>Click 'Create Group'</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Group Management Tools for Admins</h3>
<!-- /wp:heading -->

<!-- wp:heading {\"level\":4} -->
<h4>Managing Members</h4>
<!-- /wp:heading -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Navigate to the group</li><li>Click 'Manage' tab</li><li>Select 'Members'</li><li>From here you can:
<ul><li>Promote/demote members</li><li>Remove members</li><li>Ban problematic users</li><li>Manage membership requests</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":4} -->
<h4>Group Settings</h4>
<!-- /wp:heading -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Navigate to the group</li><li>Click 'Manage' tab</li><li>Select 'Settings'</li><li>Here you can modify:
<ul><li>Group name and description</li><li>Group avatar</li><li>Privacy settings</li><li>Group features</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Group Roles and Permissions</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyPress has three group roles:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li><strong>Admin</strong>: Full control over group</li><li><strong>Moderator</strong>: Can moderate content and members</li><li><strong>Member</strong>: Standard access to group content</li></ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>To change a member's role:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to the Members list</li><li>Find the member</li><li>Click on their current role</li><li>Select the new role from the dropdown</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Group Discussion Forums</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>To enable forums, you'll need bbPress installed. Once active:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to group settings</li><li>Enable the forum feature</li><li>Members can now start discussions</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Best Practices for Group Management</h3>
<!-- /wp:heading -->

<!-- wp:list -->
<ul><li>Create clear guidelines for each group</li><li>Assign multiple administrators for active groups</li><li>Regularly review membership requests</li><li>Archive inactive groups rather than deleting them</li><li>Use group announcements for important updates</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Customizing Group Features</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>You can extend group functionality with plugins:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>BuddyPress Group Email Subscription</li><li>BuddyPress Docs</li><li>GamiPress for BuddyPress</li></ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>In the next tutorial, we'll cover setting up group discussions to facilitate engagement within your community groups.</p>
<!-- /wp:paragraph -->

<!-- data-tutorial-slug=\"creating-and-managing-groups\" data-next-tutorial=\"setting-up-group-discussions\" -->" --post_category=$group_management_id --post_status=publish --porcelain --path=/var/www/html)
echo "Created 'Creating and Managing Groups' tutorial with ID: $groups_bp_id"

discussions_bp_id=$(wp post create --post_title="Setting Up Group Discussions" --post_name="setting-up-group-discussions" --post_author="1" --post_date="2025-03-30 14:20:00" --post_content="${TUTORIAL_GAMIFICATION_HEADER}
<!-- wp:heading -->
<h2>Setting Up Group Discussions in BuddyPress</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Group discussions are central to creating engagement in your BuddyPress community. This tutorial will guide you through setting up and managing effective group discussions.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Discussion Types in BuddyPress</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyPress offers two main types of group discussions:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li><strong>Activity Updates</strong>: Quick posts and comments within the group activity stream</li><li><strong>Forum Discussions</strong>: More structured conversations (requires bbPress)</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Enabling Group Forums with bbPress</h3>
<!-- /wp:heading -->

<!-- wp:list {\"ordered\":true} -->
<ol><li><strong>Install bbPress</strong>:
<ul><li>Go to Plugins &gt; Add New</li><li>Search for 'bbPress'</li><li>Install and activate</li></ul>
</li><li><strong>Enable BuddyPress-bbPress Integration</strong>:
<ul><li>Go to Settings &gt; BuddyPress &gt; Options</li><li>Enable 'bbPress Integration'</li><li>Save changes</li></ul>
</li><li><strong>Activate Forums for Groups</strong>:
<ul><li>Go to BuddyPress &gt; Settings</li><li>Enable 'Allow group creators to enable discussion forum'</li><li>Save changes</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Creating Forums for Existing Groups</h3>
<!-- /wp:heading -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Navigate to the group as an admin</li><li>Go to 'Manage' &gt; 'Details'</li><li>Enable the 'Forum' feature</li><li>Save changes</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Forum Structure Within Groups</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Once enabled, each group gets:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>A dedicated forum area</li><li>Ability to create topics (threads)</li><li>Ability to reply to topics</li><li>Notification options for members</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Creating Discussion Topics</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>As a group member:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Navigate to the group</li><li>Select the 'Forum' tab</li><li>Click 'New Topic'</li><li>Enter title and content</li><li>Set topic tags (optional)</li><li>Select options like subscription preferences</li><li>Click 'Post'</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Discussion Moderation Tools</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Group admins and moderators can:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>Sticky important topics</li><li>Close topics to prevent new replies</li><li>Spam-flag problematic content</li><li>Delete inappropriate content</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Enhancing Discussions with Media</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Enhance discussions by installing plugins that allow:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>Image attachments</li><li>Document sharing</li><li>Video embeds</li><li>GIF integration</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Notification Settings</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Members can manage their notification preferences:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to their profile settings</li><li>Navigate to 'Notifications'</li><li>Configure forum and discussion alerts</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Best Practices for Group Discussions</h3>
<!-- /wp:heading -->

<!-- wp:list -->
<ul><li>Create clear posting guidelines</li><li>Start with a few engaging topics to spark conversation</li><li>Assign topic categories if your forum grows large</li><li>Regularly participate as an administrator</li><li>Feature the most helpful or interesting discussions</li><li>Encourage members to use the subscription feature</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Common Issues and Solutions</h3>
<!-- /wp:heading -->

<!-- wp:list -->
<ul><li><strong>Low Participation</strong>: Create a 'Welcome' or 'Introduce Yourself' topic</li><li><strong>Off-Topic Posts</strong>: Create specific threads for different conversation types</li><li><strong>Spam</strong>: Implement moderation rules and approval workflows</li><li><strong>Overwhelming Volume</strong>: Organize with tags and categories</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Measuring Discussion Success</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Monitor these metrics to gauge discussion health:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>Number of new topics per week</li><li>Average replies per topic</li><li>Member participation percentage</li><li>Topic view counts</li></ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>In the next tutorial, we'll explore organizing group events to further engage your community members.</p>
<!-- /wp:paragraph -->

${INCOMPLETE_TUTORIAL_FOOTER}" --post_category=$group_management_id --post_status=publish --porcelain --path=/var/www/html)
echo "Created 'Setting Up Group Discussions' tutorial with ID: $discussions_bp_id"

# BuddyX Theme tutorial
buddyx_intro_id=$(wp post create --post_title="Introduction to BuddyX Theme" --post_name="introduction-to-buddyx-theme" --post_author="1" --post_date="2025-03-31 08:45:00" --post_content="${TUTORIAL_GAMIFICATION_HEADER}
<!-- wp:heading -->
<h2>Introduction to BuddyX Theme</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyX is a modern, lightweight theme specifically designed for BuddyPress websites. It enhances the social networking features of your site while providing a clean, responsive design.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>What is BuddyX?</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyX is a WordPress theme built to work seamlessly with BuddyPress. It provides specialized styling and layouts for all BuddyPress components, ensuring your social network not only functions well but looks great too.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Key Features of BuddyX</h3>
<!-- /wp:heading -->

<!-- wp:list -->
<ul><li><strong>BuddyPress Integration</strong>: Perfectly styled BuddyPress elements</li><li><strong>Responsive Design</strong>: Works flawlessly on all devices</li><li><strong>Customizer Options</strong>: Extensive theme customization without coding</li><li><strong>Header Variations</strong>: Multiple header layout options</li><li><strong>Dark Mode</strong>: Built-in dark mode support</li><li><strong>WooCommerce Compatible</strong>: Integrates with online stores</li><li><strong>RTL Support</strong>: Right-to-left language compatibility</li><li><strong>Performance Optimized</strong>: Fast loading speeds</li><li><strong>Accessibility Ready</strong>: Follows accessibility best practices</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>BuddyX vs. Other BuddyPress Themes</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Compared to other BuddyPress themes, BuddyX offers:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li>More modern design aesthetics</li><li>Better performance metrics</li><li>More customization options</li><li>Regular updates and support</li><li>Community-focused layout decisions</li></ul>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>BuddyX Theme Structure</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>The theme organizes BuddyPress content with:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li><strong>Activity Focused Layout</strong>: Prominent activity streams</li><li><strong>Simplified Navigation</strong>: Intuitive menus and user journeys</li><li><strong>Member-Centric Design</strong>: Emphasis on user profiles and connections</li><li><strong>Group Layouts</strong>: Well-organized group pages</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Getting Started with BuddyX</h3>
<!-- /wp:heading -->

<!-- wp:list {\"ordered\":true} -->
<ol><li><strong>Installation</strong>:
<ul><li>Go to Appearance &gt; Themes &gt; Add New</li><li>Search for 'BuddyX'</li><li>Click Install and then Activate</li></ul>
</li><li><strong>Initial Setup</strong>:
<ul><li>Theme will prompt you to install recommended plugins</li><li>Follow the setup wizard if available</li><li>Configure basic colors and layout options</li></ul>
</li><li><strong>BuddyPress Configuration</strong>:
<ul><li>Ensure BuddyPress is installed and activated</li><li>Configure BuddyPress components as needed</li><li>BuddyX will automatically style these components</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>BuddyX-Specific Settings</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Find BuddyX settings in the WordPress Customizer:</p>
<!-- /wp:paragraph -->

<!-- wp:list -->
<ul><li><strong>Site Identity</strong>: Logo, site title, favicon</li><li><strong>Colors &amp; Background</strong>: Theme color scheme</li><li><strong>Typography</strong>: Font selections and sizes</li><li><strong>Layout Options</strong>: Content width, sidebar positions</li><li><strong>Header Options</strong>: Menu positions, sticky header</li><li><strong>Footer Options</strong>: Widget areas, copyright text</li><li><strong>BuddyPress</strong>: Social network specific settings</li></ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>In the next tutorial, we'll dive deeper into customizing the BuddyX theme to match your brand and create a unique community experience.</p>
<!-- /wp:paragraph -->

${TUTORIAL_GAMIFICATION_FOOTER/NEXT_TUTORIAL/customizing-buddyx-appearance}" --post_category=$buddyx_theme_id --post_status=publish --porcelain --path=/var/www/html)
echo "Created 'Introduction to BuddyX Theme' tutorial with ID: $buddyx_intro_id"

buddyx_custom_id=$(wp post create --post_title="Customizing BuddyX Appearance" --post_name="customizing-buddyx-appearance" --post_author="1" --post_date="2025-04-01 09:30:00" --post_content="${TUTORIAL_GAMIFICATION_HEADER}
<!-- wp:heading -->
<h2>Customizing BuddyX Appearance</h2>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>The BuddyX theme offers extensive customization options that allow you to create a unique look for your BuddyPress community. This tutorial guides you through personalizing your site's appearance without coding.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Accessing the Customizer</h3>
<!-- /wp:heading -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Log in to your WordPress admin area</li><li>Go to Appearance &gt; Customize</li><li>The live customizer will open with a preview panel and control panel</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Site Identity Settings</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Start with the basics:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Navigate to 'Site Identity'</li><li>Upload your site logo (recommended size: 180×50px)</li><li>Set a site title and tagline</li><li>Upload a site icon (favicon)</li><li>Click 'Publish' to save changes</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Color Scheme Customization</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyX allows extensive color customization:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to 'Colors &amp; Background'</li><li>Customize:
<ul><li><strong>Primary Color</strong>: Main accent color throughout the site</li><li><strong>Text Color</strong>: Default text color</li><li><strong>Link Color</strong>: Color for hyperlinks</li><li><strong>Link Hover Color</strong>: Color when hovering over links</li><li><strong>Background Color</strong>: Site background</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Typography Settings</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Personalize your fonts:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Navigate to 'Typography'</li><li>Customize:
<ul><li><strong>Base Typography</strong>: Font family, size, weight, etc.</li><li><strong>Headings</strong>: Font settings for H1-H6 elements</li><li><strong>Menu</strong>: Font settings for navigation items</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>BuddyX includes Google Fonts integration, giving you access to hundreds of font options.</p>
<!-- /wp:paragraph -->

<!-- wp:heading {\"level\":3} -->
<h3>Layout Customization</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Adjust your site structure:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to 'Layout Options'</li><li>Configure:
<ul><li><strong>Container Width</strong>: Overall site width</li><li><strong>Sidebar Layout</strong>: Left, right, or no sidebar</li><li><strong>Archive Layout</strong>: How post lists display</li><li><strong>Content Layout</strong>: Full width or boxed</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Header Options</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Customize your site header:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Navigate to 'Header Options'</li><li>Adjust:
<ul><li><strong>Header Layout</strong>: Choose from multiple header styles</li><li><strong>Sticky Header</strong>: Enable/disable header sticking to top</li><li><strong>Header Elements</strong>: Search, cart, buttons, etc.</li><li><strong>Mobile Menu Settings</strong>: Mobile menu behavior</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>BuddyPress-Specific Styling</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>Fine-tune BuddyPress elements:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Go to 'BuddyPress' section</li><li>Customize:
<ul><li><strong>Profile Settings</strong>: Avatar size, cover image dimensions</li><li><strong>Member Directory</strong>: Layout and display options</li><li><strong>Group Directory</strong>: Layout and display options</li><li><strong>Activity Stream</strong>: Post form position, comment display</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Adding Custom CSS</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>For advanced customization:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Navigate to 'Additional CSS'</li><li>Enter custom CSS rules</li><li>See live preview of changes</li><li>Click 'Publish' to save</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Creating Child Themes for Major Customizations</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>For extensive modifications:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Create a BuddyX child theme</li><li>Modify template files as needed</li><li>Add custom functions to the child theme's functions.php</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Using Page Templates</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyX includes several page templates:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Edit a page</li><li>In the right sidebar, find 'Page Attributes'</li><li>Select a template from the dropdown:
<ul><li>Full Width</li><li>Full Width Container</li><li>Left Sidebar</li><li>Right Sidebar</li><li>Both Sidebars</li></ul>
</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Mobile Responsiveness</h3>
<!-- /wp:heading -->

<!-- wp:paragraph -->
<p>BuddyX is mobile-first, but you can fine-tune:</p>
<!-- /wp:paragraph -->

<!-- wp:list {\"ordered\":true} -->
<ol><li>Use the Customizer's responsive preview buttons</li><li>Check all layouts on phone, tablet, and desktop views</li><li>Adjust settings that affect mobile display</li></ol>
<!-- /wp:list -->

<!-- wp:heading {\"level\":3} -->
<h3>Best Practices</h3>
<!-- /wp:heading -->

<!-- wp:list -->
<ul><li>Maintain consistent colors aligned with your brand</li><li>Use no more than 2-3 font families</li><li>Test customizations on multiple devices</li><li>Keep your design clean and uncluttered</li><li>Consider accessibility when choosing colors and fonts</li></ul>
<!-- /wp:list -->

<!-- wp:paragraph -->
<p>In the next tutorial, we'll cover BuddyX performance optimization to ensure your community site runs smoothly and loads quickly.</p>
<!-- /wp:paragraph -->

${INCOMPLETE_TUTORIAL_FOOTER}" --post_category=$buddyx_theme_id --post_status=publish --porcelain --path=/var/www/html)
echo "Created 'Customizing BuddyX Appearance' tutorial with ID: $buddyx_custom_id"

# Check permalink structure is set properly
current_permalink=$(wp option get permalink_structure --path=/var/www/html)
if [ -z "$current_permalink" ]; then
    echo "Setting permalink structure..."
    wp option update permalink_structure '/%postname%/' --path=/var/www/html
    wp rewrite flush --path=/var/www/html
fi

# Create gamification plugin for WordPress
echo "Setting up functional gamification system..."
mkdir -p /var/www/html/wp-content/plugins/simple-tutorial-gamification/assets

# Copy the plugin files
cp /usr/local/bin/devscripts/simple-gamification.php /var/www/html/wp-content/plugins/simple-tutorial-gamification/simple-tutorial-gamification.php
cp /usr/local/bin/devscripts/simple-gamification.js /var/www/html/wp-content/plugins/simple-tutorial-gamification/assets/simple-gamification.js
cp /usr/local/bin/devscripts/simple-gamification.css /var/www/html/wp-content/plugins/simple-tutorial-gamification/assets/simple-gamification.css

# Activate the plugin
wp plugin activate simple-tutorial-gamification --path=/var/www/html || echo "Failed to activate plugin, will be activated on next page load"

# Create curriculum page with interactive gamification
echo "Creating Tutorial Course Curriculum page with interactive gamification elements..."

wp post create --post_type=page --post_title="Tutorial Course Curriculum" --post_name="tutorial-course-curriculum" --post_date="2025-03-25 15:30:00" --post_status=publish --path=/var/www/html --post_content="<h3>BuddyPress &amp; BuddyX Social Network Tutorial Series</h3>

<p>Welcome to our comprehensive tutorial series on building social networks with WordPress, BuddyPress, and the BuddyX theme.</p>

<h4>Getting Started with BuddyPress</h4>
<ul style=\"list-style-type: none; padding-left: 15px;\">
  <li style=\"margin-bottom: 10px;\"><a href=\"/introduction-to-buddypress/\" class=\"tutorial-link\" data-tutorial-slug=\"introduction-to-buddypress\">Introduction to BuddyPress</a></li>
  <li style=\"margin-bottom: 10px;\"><a href=\"/installing-and-configuring-buddypress/\" class=\"tutorial-link\" data-tutorial-slug=\"installing-and-configuring-buddypress\">Installing and Configuring BuddyPress</a></li>
  <li style=\"margin-bottom: 10px;\"><a href=\"/customizing-member-profiles/\" class=\"tutorial-link\" data-tutorial-slug=\"customizing-member-profiles\">Customizing Member Profiles</a></li>
</ul>

<h4>Group Management</h4>
<ul style=\"list-style-type: none; padding-left: 15px;\">
  <li style=\"margin-bottom: 10px;\"><a href=\"/creating-and-managing-groups/\" class=\"tutorial-link\" data-tutorial-slug=\"creating-and-managing-groups\">Creating and Managing Groups</a></li>
  <li style=\"margin-bottom: 10px;\"><a href=\"/setting-up-group-discussions/\" class=\"tutorial-link\" data-tutorial-slug=\"setting-up-group-discussions\">Setting Up Group Discussions</a></li>
</ul>

<h4>BuddyX Theme</h4>
<ul style=\"list-style-type: none; padding-left: 15px;\">
  <li style=\"margin-bottom: 10px;\"><a href=\"/introduction-to-buddyx-theme/\" class=\"tutorial-link\" data-tutorial-slug=\"introduction-to-buddyx-theme\">Introduction to BuddyX Theme</a></li>
  <li style=\"margin-bottom: 10px;\"><a href=\"/customizing-buddyx-appearance/\" class=\"tutorial-link\" data-tutorial-slug=\"customizing-buddyx-appearance\">Customizing BuddyX Appearance</a></li>
</ul>

<h4>Additional Resources</h4>
<ul style=\"list-style-type: none; padding-left: 15px;\">
  <li style=\"margin-bottom: 10px;\"><a href=\"https://codex.buddypress.org/\" style=\"text-decoration: none; padding: 8px 15px; background-color: #f8f9fa; border-radius: 4px; color: #0073aa; font-weight: 500; border-left: 4px solid #0073aa; display: inline-block;\">BuddyPress Codex</a></li>
  <li style=\"margin-bottom: 10px;\"><a href=\"https://wordpress.org/plugins/buddypress/\" style=\"text-decoration: none; padding: 8px 15px; background-color: #f8f9fa; border-radius: 4px; color: #0073aa; font-weight: 500; border-left: 4px solid #0073aa; display: inline-block;\">BuddyPress Plugin Page</a></li>
  <li style=\"margin-bottom: 10px;\"><a href=\"https://wbcomdesigns.com/docs/buddyx-theme-documentation/\" style=\"text-decoration: none; padding: 8px 15px; background-color: #f8f9fa; border-radius: 4px; color: #0073aa; font-weight: 500; border-left: 4px solid #0073aa; display: inline-block;\">BuddyX Theme Documentation</a></li>
</ul>

<!-- GAMIFICATION: Achievement notifications -->
<div id=\"achievements-section\" style=\"margin-top: 30px; border: 1px solid #e0e0e0; border-radius: 8px; padding: 20px; background-color: #fafafa;\">
    <h3 style=\"border-bottom: 1px solid #e0e0e0; padding-bottom: 10px; margin-top: 0;\">Your Achievements</h3>
    
    <div class=\"achievement achievement-getting-started locked\">
        <h4 style=\"margin-top: 0;\">🏆 Achievement: Getting Started Master</h4>
        <p style=\"margin-bottom: 0;\">Complete all tutorials in the Getting Started section to earn +150 bonus points!</p>
    </div>
    
    <div class=\"achievement achievement-group-manager locked\">
        <h4 style=\"margin-top: 0;\">🏆 Achievement: Group Manager</h4>
        <p style=\"margin-bottom: 0;\">Complete the Creating and Managing Groups tutorial.</p>
    </div>
    
    <div class=\"achievement achievement-theme-explorer locked\">
        <h4 style=\"margin-top: 0;\">🏆 Achievement: Theme Explorer</h4>
        <p style=\"margin-bottom: 0;\">Complete the Introduction to BuddyX Theme tutorial.</p>
    </div>
    
    <div class=\"achievement achievement-discussion-master locked\">
        <h4 style=\"margin-top: 0;\">🏆 Achievement: Discussion Master</h4>
        <p style=\"margin-bottom: 0;\">Complete the Setting Up Group Discussions tutorial.</p>
    </div>
    
    <div class=\"achievement achievement-theme-customizer locked\">
        <h4 style=\"margin-top: 0;\">🏆 Achievement: Theme Customizer</h4>
        <p style=\"margin-bottom: 0;\">Complete the Customizing BuddyX Appearance tutorial.</p>
    </div>
    
    <div class=\"achievement achievement-bp-master locked\">
        <h4 style=\"margin-top: 0;\">🏆 Achievement: BuddyPress Master</h4>
        <p style=\"margin-bottom: 0;\">Complete all tutorials to unlock this special achievement and earn 500 bonus points!</p>
    </div>
</div>"

echo "Tutorial content for BuddyPress and BuddyX created successfully!"

# Create Allyship System
echo "Setting up Allyship System..."

# Create directory for Allyship System
mkdir -p /var/www/html/wp-content/plugins/allyship-system/assets

# Copy the Allyship System files
cp /usr/local/bin/devscripts/ally-content/allyship-system.php /var/www/html/wp-content/plugins/allyship-system/allyship-system.php

# Setup Allyship System
wp eval 'require_once(WP_CONTENT_DIR . "/plugins/allyship-system/allyship-system.php"); setup_allyship_system();' --path=/var/www/html || echo "Failed to set up Allyship System"

echo "Allyship System setup complete!"
# endregion: TUTORIAL CONTENT CREATION

# Add the Tutorial Course Curriculum page to the menu
echo "Adding Tutorial Course Curriculum page to the menu..."
MENU_ID=$(wp menu list --format=ids --path=/var/www/html | head -n 1)
if [ -n "$MENU_ID" ]; then
    wp menu item add-post $MENU_ID 36 --path=/var/www/html || true
    echo "Added curriculum page to the menu."
fi

echo "Data population completed!"