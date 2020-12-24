const messages = {
    deleted: 'Successfully Removed',
    updated: 'Successfully updated'
  }
  
  export default function getMsgText(handle) {
    return messages[handle]
  }
  