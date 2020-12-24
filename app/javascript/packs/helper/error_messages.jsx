const messages = {
    404: 'Not Found'
  }
  
  export default function getErrorMessage(error) {
    if (error.response) {
      let response = error.response
      if (messages[response.status]) {
        return messages[response.status]
      }
      if (response.data) {
        return response.data[0]
      }
    } else {
      return 'Something went wrong.'
    }
  }
  