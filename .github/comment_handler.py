import comment_trigger as ct

def testflight_handler(args):
    envs = {'GITHUB_COMMENT_TO_APPEND': ct.comment_url}
    ct.run_bitrise_workflow(workflow_id='testflight_build_github_sendback', envs=envs)

if __name__ == '__main__':
    handlers = {
        'testflight': testflight_handler
    }
    ct.main(handlers)
